"""PHOENIX public HTTP functions (contract operations)."""

import from engine {
    advance_run_state,
    pause_run_state,
    resume_run_state,
}
import from models {
    RecoveryStatus,
    RunStatus,
    Scenario,
    TaskRun,
    create_run,
    find_run,
    list_events,
    list_recoveries,
    list_steps,
    serialize_run,
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
        nodes.append(
            {
                "id": node_id,
                "kind": "step",
                "step_index": step.index,
                "name": step.name,
                "status": step.status,
            }
        );
        if len(prev_id) > 0 {
            edges.append({"from": prev_id, "to": node_id});
        }
        prev_id = node_id;
    }
    fail_id = "";
    for ev in list_events(run) {
        if ev.event_type == "FAILURE" {
            fail_id = f"failure-{ev.step_index}";
            nodes.append(
                {
                    "id": fail_id,
                    "kind": "failure",
                    "step_index": ev.step_index,
                    "label": ev.category,
                }
            );
            edges.append({"from": f"step-{ev.step_index}", "to": fail_id});
            break;
        }
    }
    recs = list_recoveries(run);
    if len(recs) > 0 and len(fail_id) > 0 {
        latest = recs[len(recs) - 1];
        rec_id = f"recovery-{len(recs)}";
        nodes.append(
            {
                "id": rec_id,
                "kind": "recovery",
                "strategy": latest.strategy,
                "status": latest.status,
            }
        );
        edges.append({"from": fail_id, "to": rec_id});
    }
    return {"run_id": run_id, "nodes": nodes, "edges": edges};
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
    return {
        "total_runs": total,
        "completed_runs": completed,
        "failures_detected": failures,
        "recoveries_verified": verified,
        "average_latency_ms": None,
        "baseline_vs_phoenix": {
            "baseline_completed": 0,
            "phoenix_completed": completed,
        },
    };
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
