import from components.graph_helpers {
    benchmark_caption,
    event_title,
    graph_node_class,
    graph_node_subtitle,
    graph_node_title,
    parse_metrics_snapshot,
    progress_percent,
    readable_diagnostic,
    recovery_is_verified,
    run_is_terminal,
    step_index_label,
    step_status_rank,
    workflow_step_class,
    timeline_empty_title,
    scenario_label,
    format_metric_line,
}

test "graph helper formatting" {
    item: dict[str, any] = {};
    item["kind"] = "recovery";
    item["strategy"] = "FALLBACK_TOOL";
    item["status"] = "VERIFIED";
    cls = graph_node_class(item);
    assert graph_node_title(item) == "Recovery branch";
    assert cls == "workflow-step graph-node graph-recovery step-verified";
    assert "FALLBACK_TOOL" in graph_node_subtitle(item);
    assert step_status_rank("COMPLETED") > step_status_rank("PENDING");
    verified: dict[str, any] = {};
    verified["strategy"] = "FALLBACK_TOOL";
    verified["status"] = "VERIFIED";
    assert recovery_is_verified(verified);
    cap = benchmark_caption(1, 4);
    assert "baseline 1" in cap;
    assert "PHOENIX 4" in cap;
    assert event_title("FAILURE") == "Failure detected";
    assert workflow_step_class("COMPLETED") == "workflow-step step-completed";
    assert run_is_terminal("COMPLETED");
    assert not run_is_terminal("RUNNING");
    assert progress_percent(2, 5) == 40;
    assert step_index_label(0) == "01";
    assert "run not found" in readable_diagnostic("run_not_found").lower();
    snap: dict[str, any] = {};
    snap["total_runs"] = 3;
    snap["completed_runs"] = 2;
    snap["failures_detected"] = 1;
    snap["recoveries_verified"] = 1;
    bvp: dict[str, any] = {};
    bvp["baseline_completed"] = 1;
    bvp["phoenix_completed"] = 4;
    snap["baseline_vs_phoenix"] = bvp;
    parsed = parse_metrics_snapshot(snap);
    assert parsed["total_runs"] == 3;
    assert parsed["phoenix_completed"] == 4;
    assert timeline_empty_title(False) == "No events to display";
    assert scenario_label("PRIMARY_503") == "Simulated API 503";
    assert format_metric_line("Runs", 3) == "Runs: 3";
}
