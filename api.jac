"""PHOENIX public HTTP functions (contract operations)."""

import datetime;

import from engine {
    advance_run_state,
    human_decision_run_state,
    pause_run_state,
    resume_run_state,
}
import from recovery { run_reliability_benchmark }
import from models {
    RecoveryStatus,
    RunStatus,
    Scenario,
    StepStatus,
    TaskRun,
    create_run,
    find_run,
    list_events,
    list_recoveries,
    list_steps,
    reset_all_runs,
    serialize_run,
}
import from tools {
    clear_all_human_overrides,
    list_fixture_sources,
    reset_fault_state,
}

def _parse_scenario(name: str) -> Scenario {
    if name == "PRIMARY_503" {
        return Scenario.PRIMARY_503;
    }
    if name == "TEMP_TIMEOUT" {
        return Scenario.TEMP_TIMEOUT;
    }
    if name == "INVALID_OUTPUT" {
        return Scenario.INVALID_OUTPUT;
    }
    if name == "PERMISSION_DENIED" {
        return Scenario.PERMISSION_DENIED;
    }
    return Scenario.NORMAL;
}

def _not_found(run_id: str) -> dict[str, any] {
    return {"ok": False, "error": "run_not_found", "run_id": run_id};
}

def:pub start_run(prompt: str, scenario: str) -> dict[str, any] {
    run = create_run(prompt, _parse_scenario(scenario));
    return serialize_run(run);
}

def:pub get_run(run_id: str) -> dict[str, any] {
    run = find_run(run_id);
    if run is None {
        return _not_found(run_id);
    }
    return serialize_run(run);
}

def:pub advance_run(run_id: str) -> dict[str, any] {
    run = find_run(run_id);
    if run is None {
        return _not_found(run_id);
    }
    return advance_run_state(run);
}

def:pub pause_run(run_id: str) -> dict[str, any] {
    run = find_run(run_id);
    if run is None {
        return _not_found(run_id);
    }
    return pause_run_state(run);
}

def:pub resume_run(run_id: str) -> dict[str, any] {
    run = find_run(run_id);
    if run is None {
        return _not_found(run_id);
    }
    return resume_run_state(run);
}

def _step_node(step: any) -> dict[str, any] {
    return {
        "id": f"step-{step.index}",
        "kind": "step",
        "step_index": step.index,
        "name": step.name,
        "status": step.status,
        "output_summary": step.output_summary,
        "error_summary": step.error_summary,
    };
}

def:pub get_run_graph(run_id: str) -> dict[str, any] {
    run = find_run(run_id);
    if run is None {
        return _not_found(run_id);
    }
    nodes: list[dict[str, any]] = [];
    edges: list[dict[str, any]] = [];
    steps = list_steps(run);
    prev_id = "";
    for step in steps {
        node_id = f"step-{step.index}";
        nodes.append(_step_node(step));
        if len(prev_id) > 0 {
            edges.append({"from": prev_id, "to": node_id, "kind": "flow"});
        }
        prev_id = node_id;
    }
    failure_events: list[any] = [];
    for ev in list_events(run) {
        if ev.event_type == "FAILURE" {
            failure_events.append(ev);
        }
    }
    for fi in range(len(failure_events)) {
        ev = failure_events[fi];
        fail_id = f"failure-{fi + 1}";
        nodes.append(
            {
                "id": fail_id,
                "kind": "failure",
                "step_index": ev.step_index,
                "label": ev.category,
                "category": ev.category,
                "detail": ev.detail,
                "simulated": ev.simulated,
            }
        );
        edges.append(
            {
                "from": f"step-{ev.step_index}",
                "to": fail_id,
                "kind": "failure",
            }
        );
    }
    recs = list_recoveries(run);
    for ri in range(len(recs)) {
        rec = recs[ri];
        rec_id = f"recovery-{ri + 1}";
        nodes.append(
            {
                "id": rec_id,
                "kind": "recovery",
                "strategy": rec.strategy,
                "status": rec.status,
                "reason": rec.reason,
                "attempt_number": rec.attempt_number,
                "requires_approval": rec.requires_approval,
            }
        );
        if ri < len(failure_events) {
            fail_id = f"failure-{ri + 1}";
            edges.append({"from": fail_id, "to": rec_id, "kind": "recovery"});
            if rec.status == RecoveryStatus.VERIFIED {
                step_idx = failure_events[ri].step_index;
                edges.append(
                    {
                        "from": rec_id,
                        "to": f"step-{step_idx}",
                        "kind": "resume",
                    }
                );
            }
        }
    }
    return {"run_id": run_id, "nodes": nodes, "edges": edges};
}

def _step_duration_ms(events: list[any], step_index: int) -> int | None {
    started: str | None = None;
    completed: str | None = None;
    for ev in events {
        if ev.step_index != step_index {
            continue;
        }
        if ev.event_type == "STEP_STARTED" {
            started = ev.timestamp;
        }
        if ev.event_type == "STEP_COMPLETED" {
            completed = ev.timestamp;
        }
    }
    if started is None or completed is None {
        return None;
    }
    try {
        t0 = datetime.datetime.fromisoformat(started);
        t1 = datetime.datetime.fromisoformat(completed);
        delta = t1 - t0;
        return int(delta.total_seconds() * 1000);
    } except Exception {
        return None;
    }
}

def _average_step_latency_ms() -> int | None {
    durations: list[int] = [];
    for run in [root -->][?:TaskRun] {
        events = list_events(run);
        for idx in range(5) {
            ms = _step_duration_ms(events, idx);
            if ms is not None {
                durations.append(ms);
            }
        }
    }
    if len(durations) == 0 {
        return None;
    }
    total = 0;
    for d in durations {
        total += d;
    }
    return total // len(durations);
}

def:pub get_metrics -> dict[str, any] {
    total = 0;
    completed = 0;
    failures = 0;
    verified = 0;
    for run in [root -->][?:TaskRun] {
        total += 1;
        if run.status == RunStatus.COMPLETED {
            completed += 1;
        }
        for ev in list_events(run) {
            if ev.event_type == "FAILURE" {
                failures += 1;
            }
        }
        for rec in list_recoveries(run) {
            if rec.status == RecoveryStatus.VERIFIED {
                verified += 1;
            }
        }
    }
    bench = run_reliability_benchmark();
    baseline_completed = int(bench["baseline_completed"]);
    phoenix_completed = int(bench["phoenix_completed"]);
    return {
        "total_runs": total,
        "completed_runs": completed,
        "failures_detected": failures,
        "recoveries_verified": verified,
        "average_latency_ms": _average_step_latency_ms(),
        "baseline_vs_phoenix": {
            "baseline_completed": baseline_completed,
            "phoenix_completed": phoenix_completed,
        },
    };
}

def:pub human_decision(run_id: str, approved: bool) -> dict[str, any] {
    run = find_run(run_id);
    if run is None {
        return _not_found(run_id);
    }
    return human_decision_run_state(run, approved);
}

def:pub reset_demo(scope: str) -> dict[str, any] {
    if scope != "session_runs" and scope != "all_demo" {
        return {"ok": False, "error": "invalid_scope", "scope": scope};
    }
    removed = reset_all_runs();
    clear_all_human_overrides();
    return {"ok": True, "scope": scope, "runs_removed": removed};
}

def:pub get_fixture_sources -> list[dict[str, any]] {
    return list_fixture_sources();
}

def:pub list_runs -> list[dict[str, any]] {
    out: list[dict[str, any]] = [];
    for run in [root -->][?:TaskRun] {
        out.append(
            {
                "run_id": run.run_id,
                "status": run.status,
                "prompt": run.prompt,
                "scenario": run.scenario,
            }
        );
    }
    return out;
}
