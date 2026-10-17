"""Graph and status helpers for the PHOENIX dashboard (Jac-only UI logic)."""

def _graph_field(graph_item: dict[str, any], key: str, fallback: str) -> str {
    if key in graph_item {
        return str(graph_item[key]);
    }
    return fallback;
}

def graph_node_class(graph_item: dict[str, any]) -> str {
    kind = _graph_field(graph_item, "kind", "step");
    status = _graph_field(
        graph_item,
        "status",
        _graph_field(graph_item, "label", "PENDING"),
    );
    slug = status.lower().replace(" ", "-");
    return (
        "workflow-step graph-node graph-"
        + kind
        + " step-"
        + slug
    );
}

def graph_node_title(graph_item: dict[str, any]) -> str {
    kind = _graph_field(graph_item, "kind", "step");
    if kind == "failure" {
        return "Failure branch";
    }
    if kind == "recovery" {
        return "Recovery branch";
    }
    return _graph_field(graph_item, "name", "Step");
}

def graph_node_subtitle(graph_item: dict[str, any]) -> str {
    kind = _graph_field(graph_item, "kind", "step");
    if kind == "failure" {
        return _graph_field(graph_item, "label", "Failure");
    }
    if kind == "recovery" {
        strat = _graph_field(graph_item, "strategy", "Recovery");
        stat = _graph_field(graph_item, "status", "");
        return f"{strat} · {stat.replace('_', ' ')}";
    }
    return _graph_field(graph_item, "status", "PENDING").replace("_", " ");
}

def run_status_pill_class(status: str) -> str {
    slug = status.lower().replace("_", "-");
    return f"run-status-pill status-{slug}";
}

def format_metric_line(label: str, value: int) -> str {
    return f"{label}: {value}";
}

def benchmark_caption(baseline: int, phoenix: int) -> str {
    return (
        "Fixture benchmark (5 scenarios): baseline "
        + str(baseline)
        + " vs PHOENIX "
        + str(phoenix)
        + " completed reports"
    );
}

def step_status_rank(status: str) -> int {
    if status == "COMPLETED" {
        return 4;
    }
    if status == "RUNNING" {
        return 3;
    }
    if status == "FAILED" {
        return 2;
    }
    if status == "PENDING" {
        return 1;
    }
    return 0;
}

def recovery_is_verified(recovery: dict[str, any]) -> bool {
    return (
        _graph_field(recovery, "strategy", "") == "FALLBACK_TOOL"
        and _graph_field(recovery, "status", "") == "VERIFIED"
    );
}

def demo_ready_message(done: bool) -> str {
    if done {
        return "Verified backup recovery is visible. Advance to finish the report.";
    }
    return "Play 503 recovery runs the demo through verified fallback.";
}

def event_css_class(event_type: str) -> str {
    slug = event_type.lower().replace("_", "-");
    return f"event-item event-{slug}";
}

def recovery_record_heading(strategy: str, status: str) -> str {
    return f"{strategy} ({status.replace('_', ' ')})";

}

def metrics_has_data(total_runs: int) -> bool {
    return total_runs > 0;
}

def connection_label(has_active_run: bool) -> str {
    if has_active_run {
        return "Backend connected";
    }
    return "Waiting for backend";
}

def footer_connection_note(has_active_run: bool) -> str {
    if has_active_run {
        return "Run data is from the backend response";
    }
    return "Ready to connect to the backend";
}

def progress_caption(current_step: int, status: str) -> str {
    return f"Current step: {current_step + 1} · {status.replace('_', ' ')}";
}

def graph_panel_caption(has_active_run: bool, run_id_label: str) -> str {
    if has_active_run {
        return f"Run {run_id_label}";
    }
    return "Workflow structure";
}

def scenario_label(scenario: str) -> str {
    if scenario == "PRIMARY_503" {
        return "Simulated API 503";
    }
    if scenario == "TEMP_TIMEOUT" {
        return "Simulated timeout";
    }
    if scenario == "INVALID_OUTPUT" {
        return "Simulated invalid output";
    }
    if scenario == "PERMISSION_DENIED" {
        return "Simulated permission denied";
    }
    return "Normal run";
}

def advance_button_disabled(status: str, request_busy: bool) -> bool {
    if request_busy {
        return True;
    }
    if status == "PAUSED" {
        return True;
    }
    return False;
}

def event_title(event_type: str) -> str {
    if event_type == "STEP_STARTED" {
        return "Step started";
    }
    if event_type == "STEP_COMPLETED" {
        return "Step completed";
    }
    if event_type == "TOOL_EXECUTED" {
        return "Tool executed";
    }
    if event_type == "FAILURE" {
        return "Failure detected";
    }
    if event_type == "STRATEGY_SELECTED" {
        return "Recovery strategy selected";
    }
    if event_type == "RECOVERY_STARTED" {
        return "Recovery started";
    }
    if event_type == "RECOVERY_VERIFIED" {
        return "Recovery verified";
    }
    if event_type == "RUN_RESUMED" {
        return "Run resumed";
    }
    if event_type == "RUN_PAUSED" {
        return "Run paused";
    }
    if event_type == "NEEDS_HUMAN" {
        return "Human action required";
    }
    if event_type == "RUN_COMPLETED" {
        return "Run completed";
    }
    return event_type.replace("_", " ").lower().capitalize();
}

def workflow_step_class(step_status: str) -> str {
    slug = step_status.lower().replace("_", "-");
    return "workflow-step step-" + slug;
}

def run_is_terminal(status: str) -> bool {
    return (
        status == "COMPLETED"
        or status == "STOPPED"
        or status == "PAUSED"
        or status == "NEEDS_HUMAN"
    );
}

def progress_percent(completed: int, total: int) -> int {
    if total <= 0 {
        return 0;
    }
    return completed * 100 // total;
}

def readable_diagnostic(message: str) -> str {
    if message == "run_not_found" {
        return "Run not found. The run ID may be invalid or unavailable. Start a new run or retry the refresh.";
    }
    normalized = message.lower();
    if (
        "failed to fetch" in normalized
        or "networkerror" in normalized
        or "network error" in normalized
        or "load failed" in normalized
    ) {
        return "Cannot reach the PHOENIX server. Check that it is running, then retry the request.";
    }
    if "timed out" in normalized or "timeout" in normalized {
        return "The PHOENIX server did not respond in time. Retry the request or refresh the run.";
    }
    return message.replace("_", " ");
}

def parse_metrics_snapshot(snapshot: dict[str, any]) -> dict[str, int] {
    total = int(snapshot.get("total_runs", 0));
    completed = int(snapshot.get("completed_runs", 0));
    failures = int(snapshot.get("failures_detected", 0));
    verified = int(snapshot.get("recoveries_verified", 0));
    baseline = 0;
    phoenix = 0;
    bvp = snapshot.get("baseline_vs_phoenix", {});
    if isinstance(bvp, dict) {
        baseline = int(bvp.get("baseline_completed", 0));
        phoenix = int(bvp.get("phoenix_completed", 0));
    }
    return {
        "total_runs": total,
        "completed_runs": completed,
        "failures_detected": failures,
        "recoveries_verified": verified,
        "baseline_completed": baseline,
        "phoenix_completed": phoenix,
    };
}

def refresh_button_label(request_busy: bool, api_error: str) -> str {
    if request_busy {
        return "Refreshing...";
    }
    if len(api_error) > 0 {
        return "Retry display / Refresh";
    }
    return "Refresh from server";
}

def step_index_label(index: int) -> str {
    n = index + 1;
    if n < 10 {
        return "0" + str(n);
    }
    return str(n);
}

def status_display(status: str) -> str {
    return status.replace("_", " ");
}

def rpc_unwrap_payload(response: dict[str, any]) -> dict[str, any] {
    rid = response.get("run_id", "");
    if isinstance(rid, str) and len(rid) > 0 {
        return response;
    }
    data = response.get("data");
    if isinstance(data, dict) {
        inner = data.get("result");
        if isinstance(inner, dict) {
            return inner;
        }
    }
    return response;
}

def rpc_response_failed(response: dict[str, any]) -> bool {
    if response.get("ok") == False {
        return True;
    }
    if response.get("type") == "error" {
        return True;
    }
    err = response.get("error");
    if isinstance(err, dict) {
        return True;
    }
    return False;
}

def rpc_error_message(response: dict[str, any]) -> str {
    err = response.get("error");
    if isinstance(err, dict) {
        msg = err.get("message", "");
        if isinstance(msg, str) and len(msg) > 0 {
            return msg;
        }
    }
    if isinstance(err, str) {
        return err;
    }
    return str(response.get("error", "Request failed."));
}

def timeline_empty_title(has_active_run: bool) -> str {
    if has_active_run {
        return "No events recorded yet";
    }
    return "No events to display";
}

def progress_empty_label(has_active_run: bool) -> str {
    if has_active_run {
        return "No progress yet";
    }
    return "No run yet";
}

def report_empty_title(has_active_run: bool) -> str {
    if has_active_run {
        return "Report not ready";
    }
    return "Your verified report will appear here.";
}

glob MAX_RETRIES_PER_STEP_UI: int = 2;
glob MAX_RECOVERIES_PER_RUN_UI: int = 3;

def policy_snapshot(state: dict[str, any]) -> dict[str, any] {
    category = "";
    strategy = "";
    reason = "";
    retries = 0;
    recoveries = 0;
    events = state.get("events", []);
    if isinstance(events, list) {
        for ev in events {
            if not isinstance(ev, dict) {
                continue;
            }
            if ev.get("type") == "FAILURE" {
                category = str(ev.get("category", ""));
            }
            if ev.get("type") == "STRATEGY_SELECTED" {
                strategy = str(ev.get("category", ""));
                detail = ev.get("detail");
                if detail is not None {
                    reason = str(detail);
                }
            }
        }
    }
    recs = state.get("recoveries", []);
    if isinstance(recs, list) {
        for rec in recs {
            if not isinstance(rec, dict) {
                continue;
            }
            recoveries += 1;
            if rec.get("strategy") == "RETRY" {
                retries += 1;
            }
            if len(str(rec.get("reason", ""))) > 0 and len(reason) == 0 {
                reason = str(rec.get("reason", ""));
            }
            if len(str(rec.get("strategy", ""))) > 0 and len(strategy) == 0 {
                strategy = str(rec.get("strategy", ""));
            }
        }
    }
    retries_left = MAX_RETRIES_PER_STEP_UI - retries;
    if retries_left < 0 {
        retries_left = 0;
    }
    recoveries_left = MAX_RECOVERIES_PER_RUN_UI - recoveries;
    if recoveries_left < 0 {
        recoveries_left = 0;
    }
    return {
        "category": category,
        "strategy": strategy,
        "reason": reason,
        "retries_used": retries,
        "recoveries_used": recoveries,
        "retries_left": retries_left,
        "recoveries_left": recoveries_left,
    };
}

def repair_diff_from_events(events: list[dict[str, any]]) -> dict[str, any] | None {
    rejected: str | None = None;
    repaired: str | None = None;
    for ev in events {
        et = str(ev.get("type", ""));
        detail = ev.get("detail");
        if detail is None {
            continue;
        }
        text = str(detail);
        if et == "FAILURE" and ev.get("category") == "INVALID_OUTPUT" {
            rejected = text;
        }
        if et == "REPAIR_DIFF" {
            repaired = text;
        }
    }
    if rejected is None and repaired is None {
        return None;
    }
    return {"rejected": rejected, "repaired": repaired};
}

def checkpoint_summary(state: dict[str, any]) -> str {
    cp = state.get("checkpoint", {});
    completed = -1;
    if isinstance(cp, dict) {
        completed = int(cp.get("completed_step", -1));
    }
    if completed < 0 {
        return "No checkpoint committed yet.";
    }
    return (
        "Checkpoint preserves completed steps through "
        + str(completed + 1)
        + ". Resume continues at the first incomplete step."
    );
}

def step_durations_from_events(
    events: list[dict[str, any]],
) -> list[dict[str, any]] {
    out: list[dict[str, any]] = [];
    for idx in range(5) {
        started = "";
        completed = "";
        for ev in events {
            if not isinstance(ev, dict) {
                continue;
            }
            if int(ev.get("step_index", -1)) != idx {
                continue;
            }
            if ev.get("type") == "STEP_STARTED" {
                ts = ev.get("timestamp");
                if ts is not None {
                    started = str(ts);
                }
            }
            if ev.get("type") == "STEP_COMPLETED" {
                ts = ev.get("timestamp");
                if ts is not None {
                    completed = str(ts);
                }
            }
        }
        label = "Step " + str(idx + 1);
        if len(started) > 0 and len(completed) > 0 {
            out.append(
                {
                    "step_index": idx,
                    "label": label,
                    "started": started,
                    "completed": completed,
                }
            );
        }
    }
    return out;
}

def graph_node_selected_class(base: str, selected: bool) -> str {
    if selected {
        return base + " graph-node-selected";
    }
    return base;
}

def fixture_for_id(
    sources: list[dict[str, any]],
    source_id: str,
) -> dict[str, any] | None {
    for src in sources {
        if not isinstance(src, dict) {
            continue;
        }
        if str(src.get("source_id", "")) == source_id {
            return src;
        }
    }
    return None;
}

def average_latency_label(ms: int | None) -> str {
    if ms is None {
        return "Average step time: not enough data yet.";
    }
    return "Average step time (recorded runs): " + str(ms) + " ms";
}
