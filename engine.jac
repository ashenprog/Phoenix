"""PHOENIX workflow engine — work steps and recovery (Prompt 3–4)."""

import json;
import from models {
    RecoveryStatus,
    RunStatus,
    StepStatus,
    TaskRun,
    TaskStep,
    append_event,
    append_recovery,
    commit_checkpoint,
    list_events,
    list_recoveries,
    list_steps,
    serialize_run,
    update_step,
}
import from recovery {
    execute_recovery,
    select_strategy,
}
import from tools {
    check_report,
    extract_key_points,
    retrieve_primary,
    validate_sources,
}

def _blocked_status(status: RunStatus) -> bool {
    return (
        status == RunStatus.COMPLETED
        or status == RunStatus.STOPPED
        or status == RunStatus.NEEDS_HUMAN
        or status == RunStatus.PAUSED
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

def _failed_step(run: TaskRun) -> TaskStep | None {
    for step in list_steps(run) {
        if step.status == StepStatus.FAILED {
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

def _latest_failure_category(run: TaskRun) -> str {
    category = "UNKNOWN_ERROR";
    for ev in list_events(run) {
        if ev.event_type == "FAILURE" {
            category = ev.category;
        }
    }
    return category;
}

def _count_recoveries(run: TaskRun) -> int {
    return len(list_recoveries(run));
}

def _count_retries(run: TaskRun) -> int {
    n = 0;
    for rec in list_recoveries(run) {
        if rec.strategy == "RETRY" {
            n += 1;
        }
    }
    return n;
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

def _recovery_status_from_result(verification: str) -> RecoveryStatus {
    if verification == "VERIFIED" {
        return RecoveryStatus.VERIFIED;
    }
    if verification == "EXHAUSTED" {
        return RecoveryStatus.EXHAUSTED;
    }
    if verification == "PROPOSED" {
        return RecoveryStatus.PROPOSED;
    }
    return RecoveryStatus.FAILED;
}

def _apply_verified_action(
    run: TaskRun,
    step: TaskStep,
    strategy: str,
    action_result: dict[str, any],
) {
    summary: str | None = None;
    if strategy == "FALLBACK_TOOL" or strategy == "RETRY" {
        if step.index == 1 and action_result.get("ok") {
            records = action_result["data"].get("records", []);
            summary = json.dumps({"records": records});
        }
    }
    if strategy == "REPAIR_OUTPUT" {
        if step.index == 3 and action_result.get("ok") {
            points = action_result["data"].get("points", []);
            records = _retrieve_records(run);
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
            summary = json.dumps({"report": report_doc});
        }
    }
    update_step(run, step.index, StepStatus.COMPLETED, output_summary=summary);
    append_event(run, "RECOVERY_VERIFIED", strategy, step.index, True, None);
    append_event(run, "STEP_COMPLETED", "", step.index, False, None);
    commit_checkpoint(run, step.index);
    if step.index < 4 {
        run.current_step = step.index + 1;
    }
    run.status = RunStatus.RUNNING;
}

def _advance_recovery(run: TaskRun) -> dict[str, any] {
    failed = _failed_step(run);
    if failed is None {
        run.status = RunStatus.RUNNING;
        return serialize_run(run);
    }
    category = _latest_failure_category(run);
    history = {
        "retries_this_step": _count_retries(run),
        "recoveries_this_run": _count_recoveries(run),
    };
    pick = select_strategy(category, history);
    strategy = pick["strategy"];
    append_event(
        run,
        "STRATEGY_SELECTED",
        strategy,
        failed.index,
        True,
        pick["reason"],
    );
    if strategy == "STOP" {
        append_recovery(
            run,
            strategy,
            RecoveryStatus.EXHAUSTED,
            pick["reason"],
            _count_recoveries(run) + 1,
            pick["requires_approval"],
        );
        run.status = RunStatus.STOPPED;
        return serialize_run(run);
    }
    records = _retrieve_records(run);
    ctx = {
        "run_id": run.run_id,
        "scenario": run.scenario,
        "records": records,
        "category": category,
        "reason": pick["reason"],
        "requires_approval": pick["requires_approval"],
    };
    if strategy == "HUMAN_APPROVAL" {
        append_recovery(
            run,
            strategy,
            RecoveryStatus.PROPOSED,
            pick["reason"],
            _count_recoveries(run) + 1,
            True,
        );
        run.status = RunStatus.NEEDS_HUMAN;
        return serialize_run(run);
    }
    append_event(run, "RECOVERY_STARTED", strategy, failed.index, True, None);
    outcome = execute_recovery(ctx, strategy);
    rec_status = _recovery_status_from_result(outcome["verification_status"]);
    attempt_num = _count_recoveries(run) + 1;
    append_recovery(
        run,
        strategy,
        rec_status,
        pick["reason"],
        attempt_num,
        pick["requires_approval"],
    );
    if outcome["verification_status"] == "VERIFIED" {
        _apply_verified_action(run, failed, strategy, outcome["action_result"]);
        return serialize_run(run);
    }
    if strategy == "RESUME_CHECKPOINT" {
        run.status = RunStatus.RUNNING;
        return serialize_run(run);
    }
    if _count_recoveries(run) >= 3 {
        run.status = RunStatus.STOPPED;
    } else {
        run.status = RunStatus.RECOVERING;
    }
    return serialize_run(run);
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

def pause_run_state(run: TaskRun) -> dict[str, any] {
    if run.status == RunStatus.PAUSED {
        return serialize_run(run);
    }
    if (
        run.status == RunStatus.COMPLETED
        or run.status == RunStatus.STOPPED
        or run.status == RunStatus.NEEDS_HUMAN
    ) {
        return serialize_run(run);
    }
    run.status = RunStatus.PAUSED;
    append_event(run, "RUN_PAUSED", "", run.current_step, False, None);
    return serialize_run(run);
}

def resume_run_state(run: TaskRun) -> dict[str, any] {
    if run.status != RunStatus.PAUSED {
        return serialize_run(run);
    }
    if _failed_step(run) is not None {
        run.status = RunStatus.RECOVERING;
    } else {
        run.status = RunStatus.RUNNING;
    }
    append_event(run, "RUN_RESUMED", "", run.current_step, False, None);
    return serialize_run(run);
}

def advance_run_state(run: TaskRun) -> dict[str, any] {
    if _blocked_status(run.status) {
        return serialize_run(run);
    }
    if run.status == RunStatus.RECOVERING {
        return _advance_recovery(run);
    }
    step = _first_incomplete_step(run);
    if step is None {
        run.status = RunStatus.COMPLETED;
        return serialize_run(run);
    }
    if step.status == StepStatus.FAILED {
        return _advance_recovery(run);
    }
    run.status = RunStatus.RUNNING;
    append_event(run, "STEP_STARTED", "", step.index, False, None);
    update_step(run, step.index, StepStatus.RUNNING);
    _execute_step(run, step);
    return serialize_run(run);
}
