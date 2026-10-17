"""PHOENIX public HTTP functions (contract operations)."""

import from engine { advance_run_state }
import from models {
    Scenario,
    TaskRun,
    create_run,
    find_run,
    list_events,
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
    return {"run_id": run_id, "nodes": nodes, "edges": edges};
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
