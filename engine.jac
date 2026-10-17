"""PHOENIX workflow engine — one step per advance (Prompt 3)."""

import json;
import from models {
    RunStatus,
    StepStatus,
    TaskRun,
    TaskStep,
    append_event,
    commit_checkpoint,
    list_steps,
    serialize_run,
    update_step,
}
import from tools {
    check_report,
    extract_key_points,
    retrieve_primary,
    validate_sources,
}

def _terminal_status(status: RunStatus) -> bool {
    return (
        status == RunStatus.COMPLETED
        or status == RunStatus.STOPPED
        or status == RunStatus.NEEDS_HUMAN
        or status == RunStatus.RECOVERING
    );
}

def _first_incomplete_step(run: TaskRun) -> TaskStep | None {
    for step in list_steps(run) {
        if step.status != StepStatus.COMPLETED {
            return step;
        }
    }
    return None;
}

def _step_output_json(run: TaskRun, index: int) -> dict[str, any] | list[any] | None {
    for step in list_steps(run) {
        if step.index == index and step.output_summary is not None {
            return json.loads(step.output_summary);
        }
    }
    return None;
}

def _retrieve_records(run: TaskRun) -> list[dict[str, any]] {
    payload = _step_output_json(run, 1);
    if isinstance(payload, dict) and "records" in payload {
        recs = payload["records"];
        if isinstance(recs, list) {
            return recs;
        }
    }
    return [];
}

def _tool_failed(tool_result: dict[str, any]) -> bool {
    if not tool_result.get("ok") {
        return True;
    }
    data = tool_result.get("data", {});
    if isinstance(data, dict) and data.get("simulated_bad_schema") {
        return True;
    }
    return False;
}

def _failure_category(tool_result: dict[str, any]) -> str {
    if tool_result.get("ok") {
        return "INVALID_OUTPUT";
    }
    code = tool_result.get("error_code", "");
    if isinstance(code, str) and len(code) > 0 {
        return code;
    }
    return "UNKNOWN_ERROR";
}

def _handle_failure(
    run: TaskRun,
    step: TaskStep,
    tool_result: dict[str, any],
) {
    category = _failure_category(tool_result);
    msg = tool_result.get("error_message", "Tool failed.");
    update_step(
        run,
        step.index,
        StepStatus.FAILED,
        error_summary=str(msg),
    );
    run.status = RunStatus.RECOVERING;
    append_event(
        run,
        "FAILURE",
        category,
        step.index,
        True,
        str(msg),
    );
}

def _handle_success(run: TaskRun, step: TaskStep, summary: str | None) {
    update_step(run, step.index, StepStatus.COMPLETED, output_summary=summary);
    append_event(run, "STEP_COMPLETED", "", step.index, False, None);
    commit_checkpoint(run, step.index);
    if step.index < 4 {
        run.current_step = step.index + 1;
    }
}

def _execute_step(run: TaskRun, step: TaskStep) -> bool {
    idx = step.index;
    run_id = run.run_id;
    scenario = run.scenario;

    if idx == 0 {
        outline = f"Outline: {run.prompt}";
        _handle_success(run, step, outline);
        return True;
    }
    if idx == 1 {
        result = retrieve_primary(run_id, scenario);
        if _tool_failed(result) {
            _handle_failure(run, step, result);
            return False;
        }
        records = result["data"].get("records", []);
        payload = json.dumps({"records": records});
        _handle_success(run, step, payload);
        return True;
    }
    if idx == 2 {
        records = _retrieve_records(run);
        result = validate_sources(run_id, scenario, records);
        if _tool_failed(result) {
            _handle_failure(run, step, result);
            return False;
        }
        _handle_success(run, step, json.dumps({"valid": True, "count": len(records)}));
        return True;
    }
    if idx == 3 {
        records = _retrieve_records(run);
        result = extract_key_points(run_id, scenario, records);
        if _tool_failed(result) {
            _handle_failure(run, step, result);
            return False;
        }
        points = result["data"].get("points", []);
        source_ids: list[str] = [];
        for rec in records {
            sid = rec.get("source_id", "");
            if isinstance(sid, str) and sid not in source_ids {
                source_ids.append(sid);
            }
        }
        if len(source_ids) == 0 {
            source_ids = ["fixture-primary-1"];
        }
        report_doc = {
            "title": f"Research: {run.prompt}",
            "executive_summary": "Deterministic fixture report.",
            "findings": points if isinstance(points, list) else [str(points)],
            "recommendations": ["Continue monitoring agent reliability."],
            "source_ids": source_ids,
        };
        _handle_success(run, step, json.dumps({"report": report_doc}));
        return True;
    }
    if idx == 4 {
        gen = _step_output_json(run, 3);
        report_doc = {
            "title": f"Research: {run.prompt}",
            "executive_summary": "Deterministic fixture report.",
            "findings": ["Fixture finding."],
            "recommendations": ["Continue monitoring agent reliability."],
            "source_ids": ["fixture-primary-1"],
        };
        if isinstance(gen, dict) {
            maybe = gen.get("report");
            if isinstance(maybe, dict) {
                report_doc = maybe;
            }
        }
        result = check_report(run_id, scenario, report_doc);
        if _tool_failed(result) {
            _handle_failure(run, step, result);
            return False;
        }
        run.final_report = report_doc;
        run.status = RunStatus.COMPLETED;
        _handle_success(run, step, "verified");
        run.current_step = 4;
        append_event(run, "RUN_COMPLETED", "", 4, False, None);
        return True;
    }
    return False;
}

def advance_run_state(run: TaskRun) -> dict[str, any] {
    if _terminal_status(run.status) {
        return serialize_run(run);
    }
    step = _first_incomplete_step(run);
    if step is None {
        run.status = RunStatus.COMPLETED;
        return serialize_run(run);
    }
    run.status = RunStatus.RUNNING;
    append_event(run, "STEP_STARTED", "", step.index, False, None);
    update_step(run, step.index, StepStatus.RUNNING);
    _execute_step(run, step);
    return serialize_run(run);
}
