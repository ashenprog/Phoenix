import from .graph_helpers {
    advance_button_disabled,
    average_latency_label,
    checkpoint_summary,
    connection_label,
    demo_ready_message,
    fixture_for_id,
    footer_connection_note,
    policy_snapshot,
    progress_caption,
    progress_percent,
    readable_diagnostic,
    refresh_button_label,
    repair_diff_from_events,
    rpc_error_message,
    rpc_response_failed,
    rpc_unwrap_payload,
    run_is_terminal,
    scenario_label,
    step_durations_from_events,
}
import from ..api {
    advance_run,
    get_fixture_sources,
    get_metrics,
    get_run,
    get_run_graph,
    human_decision,
    list_runs,
    pause_run,
    reset_demo,
    resume_run,
    start_run,
}
import from "@jac/runtime" { __jacClearCache }
import from .ChaosLab { ChaosLab }
import from .ExecutionGraph { ExecutionGraph }
import from .Metrics { Metrics }
import from .RecoveryTimeline { RecoveryTimeline }

glob _request_in_flight: bool = False;
glob _active_run_id: str = "";

def _recovery_demo_done(state: dict[str, any]) -> bool {
    steps_data = state.get("steps", []);
    retrieve_ok = False;
    if isinstance(steps_data, list) and len(steps_data) > 1 {
        step1 = steps_data[1];
        if isinstance(step1, dict) and step1.get("status") == "COMPLETED" {
            retrieve_ok = True;
        }
    }
    if not retrieve_ok {
        return False;
    }
    recs = state.get("recoveries", []);
    if not isinstance(recs, list) {
        return False;
    }
    for rec in recs {
        if not isinstance(rec, dict) {
            continue;
        }
        if rec.get("strategy") == "FALLBACK_TOOL" and rec.get("status") == "VERIFIED" {
            return True;
        }
    }
    return False;
}

def _run_has_failure(state: dict[str, any]) -> bool {
    events = state.get("events", []);
    if not isinstance(events, list) {
        return False;
    }
    for ev in events {
        if isinstance(ev, dict) and ev.get("type") == "FAILURE" {
            return True;
        }
    }
    steps_data = state.get("steps", []);
    if isinstance(steps_data, list) {
        for step in steps_data {
            if isinstance(step, dict) and step.get("status") == "FAILED" {
                return True;
            }
        }
    }
    return False;
}

def:pub Dashboard() -> JsxElement {
    has prompt: str = "";
    has scenario: str = "NORMAL";
    has run_state: dict[str, any] | None = None;
    has graph_data: dict[str, any] | None = None;
    has graph_error: str = "";
    has graph_loading: bool = False;
    has metrics_data: dict[str, any] | None = None;
    has metrics_error: str = "";
    has metrics_loading: bool = True;
    has request_busy: bool = True;
    has api_error: str = "";
    has demo_paused: bool = False;
    has run_history: list[dict[str, any]] = [];
    has fixture_sources: list[dict[str, any]] = [];
    has presenter_mode: bool = False;
    has source_drawer_id: str = "";

    def handle_prompt_change(e: ChangeEvent) {
        prompt = e.target.value;
    }

    def handle_scenario_change(value: str) {
        scenario = value;
    }

    async def refresh_graph(run_id: str) {
        graph_data = None;
        graph_loading = True;
        __jacClearCache();
        try {
            response = await get_run_graph(run_id);
            if rpc_response_failed(response) {
                graph_data = None;
                graph_error = readable_diagnostic(rpc_error_message(response));
            } else {
                graph_data = rpc_unwrap_payload(response);
                graph_error = "";
            }
        } finally {
            graph_loading = False;
        }
    }

    async def refresh_metrics_data() {
        __jacClearCache();
        response = await get_metrics();
        if rpc_response_failed(response) {
            metrics_error = readable_diagnostic(rpc_error_message(response));
        } else {
            metrics_data = rpc_unwrap_payload(response);
            metrics_error = "";
        }
    }

    async def refresh_run_history() {
        try {
            response = await list_runs();
            if isinstance(response, list) {
                run_history = [];
                for item in response {
                    run_history.append(item as dict[str, any]);
                }
            }
        } except Exception as err {
            _ = err;
        }
    }

    async def refresh_fixture_sources() {
        try {
            response = await get_fixture_sources();
            if isinstance(response, list) {
                fixture_sources = [];
                for item in response {
                    fixture_sources.append(item as dict[str, any]);
                }
            }
        } except Exception as err {
            _ = err;
        }
    }

    async def refresh_auxiliary_data(run_id: str) {
        try {
            await refresh_graph(run_id);
        } except Exception as err {
            graph_error = readable_diagnostic(
                f"Could not load the workflow graph: {str(err)}"
            );
        }
        try {
            await refresh_metrics_data();
        } except Exception as err {
            metrics_error = readable_diagnostic(
                f"Could not load run metrics: {str(err)}"
            );
        }
        await refresh_run_history();
    }

    async can with entry {
        if not _request_in_flight {
            _request_in_flight = True;
            metrics_loading = True;
            request_busy = True;
            try {
                await refresh_metrics_data();
                await refresh_fixture_sources();
                await refresh_run_history();
            } except Exception as err {
                metrics_error = readable_diagnostic(
                    f"Could not load run metrics: {str(err)}"
                );
            } finally {
                _request_in_flight = False;
                metrics_loading = False;
                request_busy = False;
            }
        }
    }

    def handle_presenter_toggle(_e: MouseEvent) {
        presenter_mode = not presenter_mode;
    }

    async def handle_load_run(run_id: str) {
        if _request_in_flight or len(run_id) == 0 {
            return;
        }
        _request_in_flight = True;
        request_busy = True;
        api_error = "";
        try {
            __jacClearCache();
            response = await get_run(run_id);
            if rpc_response_failed(response) {
                api_error = readable_diagnostic(rpc_error_message(response));
            } else {
                _active_run_id = run_id;
                run_state = rpc_unwrap_payload(response);
                demo_paused = False;
                await refresh_auxiliary_data(run_id);
            }
        } except Exception as err {
            api_error = readable_diagnostic(f"Could not load run: {str(err)}");
        } finally {
            _request_in_flight = False;
            request_busy = False;
        }
    }

    async def handle_reset_demo() {
        if _request_in_flight {
            return;
        }
        _request_in_flight = True;
        request_busy = True;
        api_error = "";
        try {
            __jacClearCache();
            response = await reset_demo("session_runs");
            if isinstance(response, dict) and response.get("ok") == False {
                api_error = "Could not reset demo session.";
            } else {
                _active_run_id = "";
                run_state = None;
                graph_data = None;
                demo_paused = False;
                await refresh_metrics_data();
                await refresh_run_history();
            }
        } except Exception as err {
            api_error = readable_diagnostic(f"Could not reset demo: {str(err)}");
        } finally {
            _request_in_flight = False;
            request_busy = False;
        }
    }

    async def handle_human_approve() {
        if _request_in_flight or len(_active_run_id) == 0 {
            return;
        }
        _request_in_flight = True;
        request_busy = True;
        run_id = _active_run_id;
        try {
            response = await human_decision(run_id, True);
            if rpc_response_failed(response) {
                api_error = readable_diagnostic(rpc_error_message(response));
            } else {
                run_state = rpc_unwrap_payload(response);
                await refresh_auxiliary_data(run_id);
            }
        } finally {
            _request_in_flight = False;
            request_busy = False;
        }
    }

    async def handle_human_deny() {
        if _request_in_flight or len(_active_run_id) == 0 {
            return;
        }
        _request_in_flight = True;
        request_busy = True;
        run_id = _active_run_id;
        try {
            response = await human_decision(run_id, False);
            if rpc_response_failed(response) {
                api_error = readable_diagnostic(rpc_error_message(response));
            } else {
                run_state = rpc_unwrap_payload(response);
                await refresh_auxiliary_data(run_id);
            }
        } finally {
            _request_in_flight = False;
            request_busy = False;
        }
    }

    async def _advance_demo_until_done(run_id: str, stop_on_failure: bool) -> None {
        demo_state = run_state if run_state is not None else {"steps": [], "recoveries": [], "events": []};
        for _ in range(8) {
            if _recovery_demo_done(demo_state) {
                demo_paused = False;
                break;
            }
            adv = await advance_run(run_id);
            if rpc_response_failed(adv) {
                api_error = readable_diagnostic(rpc_error_message(adv));
                break;
            }
            demo_state = rpc_unwrap_payload(adv);
            run_state = demo_state;
            demo_status = str(demo_state.get("status", ""));
            if demo_status == "COMPLETED" {
                demo_paused = False;
                break;
            }
            if stop_on_failure and (
                demo_status == "RECOVERING"
                or demo_status == "NEEDS_HUMAN"
                or _run_has_failure(demo_state)
            ) {
                demo_paused = True;
                break;
            }
        }
    }

    async def handle_metrics_refresh() -> None {
        if _request_in_flight {
            return;
        }
        _request_in_flight = True;
        request_busy = True;
        metrics_loading = True;
        try {
            await refresh_metrics_data();
        } except Exception as err {
            metrics_error = readable_diagnostic(
                f"Could not load run metrics: {str(err)}"
            );
        } finally {
            _request_in_flight = False;
            request_busy = False;
            metrics_loading = False;
        }
    }

    async def handle_start() -> None {
        if _request_in_flight {
            return;
        }
        if len(prompt.strip()) == 0 {
            api_error = "Enter a research task before starting a run.";
            return;
        }
        _request_in_flight = True;
        request_busy = True;
        api_error = "";
        try {
            task_prompt = prompt.strip();
            prompt = task_prompt;
            __jacClearCache();
            response = await start_run(task_prompt, scenario);
            if rpc_response_failed(response) {
                api_error = readable_diagnostic(rpc_error_message(response));
            } else {
                state = rpc_unwrap_payload(response);
                run_id = str(state.get("run_id", ""));
                if len(run_id) == 0 {
                    api_error = "The server returned an invalid run without a run ID. Try starting the task again.";
                } else {
                    _active_run_id = run_id;
                    run_state = state;
                    graph_data = None;
                    graph_error = "";
                    await refresh_auxiliary_data(run_id);
                }
            }
        } except Exception as err {
            api_error = readable_diagnostic(f"Could not start the run: {str(err)}");
        } finally {
            _request_in_flight = False;
            request_busy = False;
        }
    }

    async def handle_refresh() -> None {
        if _request_in_flight or len(_active_run_id) == 0 {
            return;
        }
        _request_in_flight = True;
        request_busy = True;
        api_error = "";
        run_id = _active_run_id;
        try {
            __jacClearCache();
            response = await get_run(run_id);
            if rpc_response_failed(response) {
                api_error = readable_diagnostic(rpc_error_message(response));
            } else {
                run_state = rpc_unwrap_payload(response);
                await refresh_auxiliary_data(run_id);
            }
        } except Exception as err {
            api_error = readable_diagnostic(f"Could not refresh this run: {str(err)}");
        } finally {
            _request_in_flight = False;
            request_busy = False;
        }
    }

    async def handle_advance() -> None {
        if _request_in_flight or len(_active_run_id) == 0 {
            return;
        }
        _request_in_flight = True;
        request_busy = True;
        api_error = "";
        run_id = _active_run_id;
        try {
            __jacClearCache();
            response = await advance_run(run_id);
            if rpc_response_failed(response) {
                api_error = readable_diagnostic(rpc_error_message(response));
            } else {
                run_state = rpc_unwrap_payload(response);
                await refresh_auxiliary_data(run_id);
            }
        } except Exception as err {
            api_error = readable_diagnostic(f"Could not advance this run: {str(err)}");
        } finally {
            _request_in_flight = False;
            request_busy = False;
        }
    }

    async def handle_run_control(resume: bool) -> None {
        if _request_in_flight or len(_active_run_id) == 0 {
            return;
        }
        _request_in_flight = True;
        request_busy = True;
        api_error = "";
        run_id = _active_run_id;
        response: dict[str, any] = {};
        try {
            __jacClearCache();
            if resume {
                response = await resume_run(run_id);
            } else {
                response = await pause_run(run_id);
            }
            if rpc_response_failed(response) {
                api_error = readable_diagnostic(rpc_error_message(response));
            } else {
                run_state = rpc_unwrap_payload(response);
                await refresh_auxiliary_data(run_id);
            }
        } except Exception as err {
            api_error = readable_diagnostic(
                f"Could not {resume and 'resume' or 'pause'} this run: {str(err)}"
            );
        } finally {
            _request_in_flight = False;
            request_busy = False;
        }
    }

    async def handle_pause(_e: MouseEvent) {
        await handle_run_control(False);
    }

    async def handle_resume(_e: MouseEvent) {
        await handle_run_control(True);
    }

    async def handle_play_503() -> None {
        if _request_in_flight {
            return;
        }
        _request_in_flight = True;
        request_busy = True;
        api_error = "";
        try {
            task_prompt = prompt.strip();
            if len(task_prompt) == 0 {
                task_prompt = "Demo: simulated primary API 503 recovery";
                prompt = task_prompt;
            }
            scenario = "PRIMARY_503";
            __jacClearCache();
            response = await start_run(task_prompt, scenario);
            if rpc_response_failed(response) {
                api_error = readable_diagnostic(rpc_error_message(response));
                return;
            }
            state = rpc_unwrap_payload(response);
            run_id = str(state.get("run_id", ""));
            if len(run_id) == 0 {
                api_error = "Could not start the recovery demo run.";
                return;
            }
            _active_run_id = run_id;
            run_state = state;
            demo_paused = False;
            await _advance_demo_until_done(run_id, True);
            graph_data = None;
            graph_error = "";
            await refresh_auxiliary_data(run_id);
        } except Exception as err {
            api_error = readable_diagnostic(
                f"Could not play the recovery demo: {str(err)}"
            );
        } finally {
            _request_in_flight = False;
            request_busy = False;
        }
    }

    async def handle_continue_demo() {
        if _request_in_flight or len(_active_run_id) == 0 {
            return;
        }
        _request_in_flight = True;
        request_busy = True;
        run_id = _active_run_id;
        try {
            demo_paused = False;
            await _advance_demo_until_done(run_id, False);
            await refresh_auxiliary_data(run_id);
        } finally {
            _request_in_flight = False;
            request_busy = False;
        }
    }

    async def handle_history_select(e: ChangeEvent) {
        run_id = str(e.target.value);
        if len(run_id) > 0 {
            await handle_load_run(run_id);
        }
    }

    def handle_source_select_change(e: ChangeEvent) {
        source_drawer_id = str(e.target.value);
    }

    async def handle_refresh_history_click(_e: MouseEvent) {
        await refresh_run_history();
    }

    async def handle_keydown(e: KeyboardEvent) {
        if not presenter_mode {
            return;
        }
        key = e.key;
        if key == "n" or key == "N" {
            await handle_advance();
        }
    }

    status = "PENDING";
    current_step = 0;
    completed_count = 0;
    step_total = 5;
    steps: list[dict[str, any]] = [];
    events: list[dict[str, any]] = [];
    recoveries: list[dict[str, any]] = [];
    final_report_data: dict[str, any] = {
        "title": "",
        "executive_summary": "",
        "findings": [],
        "recommendations": [],
        "source_ids": [],
    };
    findings: list[str] = [];
    recommendations: list[str] = [];
    source_ids: list[str] = [];
    graph_nodes: list[dict[str, any]] = [];
    graph_edges: list[dict[str, any]] = [];
    if graph_data is not None {
        graph_nodes_data = graph_data.get("nodes", []);
        if isinstance(graph_nodes_data, list) {
            for graph_node_data in graph_nodes_data {
                graph_nodes.append(graph_node_data as dict[str, any]);
            }
        }
        graph_edges_data = graph_data.get("edges", []);
        if isinstance(graph_edges_data, list) {
            for graph_edge_data in graph_edges_data {
                graph_edges.append(graph_edge_data as dict[str, any]);
            }
        }
    }
    has_report = False;
    if run_state is not None {
        status = str(run_state.get("status", "UNKNOWN"));
        current_step = int(run_state.get("current_step", 0));
        steps_data = run_state.get("steps", []);
        if isinstance(steps_data, list) {
            for step_data in steps_data {
                steps.append(step_data as dict[str, any]);
            }
            step_total = len(steps);
            for step in steps {
                if step.get("status") == "COMPLETED" {
                    completed_count = completed_count + 1;
                }
            }
        }
        event_data = run_state.get("events", []);
        if isinstance(event_data, list) {
            for event in event_data {
                events.append(event as dict[str, any]);
            }
        }
        recovery_data = run_state.get("recoveries", []);
        if isinstance(recovery_data, list) {
            for recovery in recovery_data {
                recoveries.append(recovery as dict[str, any]);
            }
        }
        report_data = run_state.get("final_report");
        if report_data {
            final_report_data = report_data as dict[str, any];
            has_report = True;
            findings_data = final_report_data.get("findings", []);
            if isinstance(findings_data, list) {
                for finding in findings_data {
                    findings.append(str(finding));
                }
            }
            recommendations_data = final_report_data.get("recommendations", []);
            if isinstance(recommendations_data, list) {
                for recommendation in recommendations_data {
                    recommendations.append(str(recommendation));
                }
            }
            source_ids_data = final_report_data.get("source_ids", []);
            if isinstance(source_ids_data, list) {
                for source_id in source_ids_data {
                    source_ids.append(str(source_id));
                }
            }
        }
    }
    terminal = run_is_terminal(status);
    progress_pct = progress_percent(completed_count, step_total);
    model_mode = "DETERMINISTIC_FALLBACK";
    has_active_run = run_state is not None;
    run_id_label = "";
    if run_state is not None {
        run_id_label = str(run_state.get("run_id", ""));
        model_mode = str(run_state.get("model_mode", "DETERMINISTIC_FALLBACK"));
    }
    demo_done = False;
    if run_state is not None {
        demo_done = _recovery_demo_done(run_state);
    }
    policy_data: dict[str, any] | None = None;
    repair_diff_data: dict[str, any] | None = None;
    step_timings: list[dict[str, any]] = [];
    checkpoint_text = "";
    avg_latency_note = "";
    selected_fixture: dict[str, any] | None = None;
    if run_state is not None {
        policy_data = policy_snapshot(run_state);
        repair_diff_data = repair_diff_from_events(events);
        step_timings = step_durations_from_events(events);
        checkpoint_text = checkpoint_summary(run_state);
    }
    if metrics_data is not None {
        latency_raw = metrics_data.get("average_latency_ms");
        ms_val: int | None = None;
        if latency_raw is not None and str(latency_raw) != "None" {
            ms_val = int(latency_raw);
        }
        avg_latency_note = average_latency_label(ms_val);
    }
    if len(source_drawer_id) > 0 {
        selected_fixture = fixture_for_id(fixture_sources, source_drawer_id);
    }
    app_class = "phoenix-app";
    if presenter_mode {
        app_class = "phoenix-app presenter-mode";
    }

    return <main className={app_class} tabIndex={0} onKeyDown={handle_keydown}>
        <header className="topbar">
            <a className="brand" href="#" aria-label="Phoenix home">
                <span className="brand-mark" aria-hidden="true">P</span>
                <span>PHOENIX</span>
            </a>
            <div className="topbar-meta">
                <button className="secondary-button presenter-toggle" type="button" onClick={handle_presenter_toggle}>
                    {presenter_mode and "Exit presenter mode" or "Presenter mode"}
                </button>
                <span className="environment-pill"><span className="status-dot"></span>Local workspace</span>
                <span className="connection-state">{connection_label(has_active_run)}</span>
            </div>
        </header>
        {presenter_mode and has_active_run and <section className="presenter-strip" aria-live="polite">
            <strong>{status.replace("_", " ")}</strong>
            <span>{progress_caption(current_step, status)}</span>
            <span className="presenter-hint">Press N to advance one step</span>
        </section>}

        <section className="welcome-row" aria-labelledby="page-title">
            <div>
                <p className="eyebrow">RELIABLE RESEARCH WORKFLOWS</p>
                <h1 id="page-title">Run monitor</h1>
                <p className="page-description">Start a task and follow its progress, recovery events, and verified result.</p>
            </div>
            <div className={"run-status status-" + status.lower()}>
                <span className="status-dot status-dot-muted"></span>
                {status.replace("_", " ")}
            </div>
        </section>

        <section className="control-card" aria-labelledby="new-run-title">
            <div className="section-heading">
                <div>
                    <p className="eyebrow">NEW WORKFLOW</p>
                    <h2 id="new-run-title">Start a research task</h2>
                </div>
                <span className="step-count">5 steps</span>
            </div>
            <div className="run-form">
                <label className="field-label" htmlFor="task-prompt">What should PHOENIX research?</label>
                <textarea
                    id="task-prompt"
                    className="task-input"
                    placeholder="For example: Research how teams improve AI agent reliability"
                    value={prompt}
                    onChange={handle_prompt_change}
                    rows={3}
                />
                <div className="form-actions">
                    <ChaosLab scenario={scenario} onScenarioChange={handle_scenario_change} />
                    <button className="start-button" type="button" disabled={request_busy or len(prompt.strip()) == 0} onClick={handle_start}>
                        <span aria-hidden="true">▶</span>
                        {request_busy and "Working..." or "Start run"}
                    </button>
                    <button className="demo-button" type="button" disabled={request_busy} onClick={handle_play_503}>
                        Play 503 recovery
                    </button>
                    {demo_paused and <button className="advance-button" type="button" disabled={request_busy} onClick={handle_continue_demo}>
                        Continue demo
                    </button>}
                    <button className="secondary-button" type="button" disabled={request_busy} onClick={handle_reset_demo}>
                        Reset demo
                    </button>
                </div>
                {api_error and not has_active_run and <p className="form-error" role="alert">{api_error}</p>}
                {not api_error and <p className="form-note" role="status">
                    {demo_paused
                        and "Demo paused on the first simulated failure. Click Continue demo to finish recovery."
                        or demo_ready_message(demo_done)}
                </p>}
            </div>
        </section>

        <section className="panel run-history-panel" aria-labelledby="run-history-title">
            <div className="panel-heading">
                <div>
                    <p className="eyebrow">SESSION</p>
                    <h2 id="run-history-title">Run history</h2>
                </div>
                <button className="secondary-button" type="button" disabled={request_busy} onClick={handle_refresh_history_click}>
                    Refresh list
                </button>
            </div>
            {if len(run_history) == 0 {
                <p className="muted-copy">No recorded runs yet.</p>
            } else {
                <label className="field-label" htmlFor="run-history-select">Load a recorded run</label>
                <select
                    id="run-history-select"
                    className="scenario-select"
                    disabled={request_busy}
                    onChange={handle_history_select}
                >
                    <option value="">Select run…</option>
                    {for (index, hist) in enumerate(run_history) {
                        hist_id = str(hist.get("run_id", ""));
                        label = (
                            str(hist.get("prompt", "Run"))[:40]
                            + " · "
                            + scenario_label(str(hist.get("scenario", "NORMAL")))
                            + " · "
                            + str(hist.get("status", ""))
                        );
                        <option value={hist_id} key={str(index)}>{label}</option>
                    }}
                </select>
            }}
        </section>

        <section className="overview-grid" aria-label="Run overview">
            <article className="panel progress-panel">
                <div className="panel-heading">
                    <div>
                        <p className="eyebrow">CURRENT RUN</p>
                        <h2>Progress</h2>
                    </div>
                    <span className="empty-tag">{has_active_run and run_id_label or "No run yet"}</span>
                </div>
                <div className="progress-summary">
                    <span className="progress-number">{has_active_run and str(completed_count) or "—"}</span>
                    <span className="progress-copy">
                        {has_active_run and f"of {step_total} steps completed" or "steps completed"}
                    </span>
                </div>
                <div className="progress-track" role="progressbar" aria-label="Completed workflow steps" aria-valuemin={0} aria-valuemax={step_total} aria-valuenow={completed_count}>
                    <span style={{"width": f"{progress_pct}%"}}></span>
                </div>
                <p className="muted-copy">
                    {has_active_run and progress_caption(current_step, status) or "Run progress will appear here after a task starts."}
                </p>
                {has_active_run and len(checkpoint_text) > 0 and <p className="checkpoint-viewer">{checkpoint_text}</p>}
                {len(step_timings) > 0 and <ul className="step-timing-list">
                    {for timing in step_timings {
                        <li key={str(timing.get("step_index", 0))}>
                            {str(timing.get("label", "Step"))}: recorded start → complete
                        </li>
                    }}
                </ul>}
                {len(avg_latency_note) > 0 and <p className="muted-copy">{avg_latency_note}</p>}
                {api_error and has_active_run and <p className="form-error" role="alert">{api_error}</p>}
                {status == "NEEDS_HUMAN" and <div className="human-gate">
                    <p>Permission denied — approve backup retrieve or deny to stop.</p>
                    <button className="advance-button" type="button" disabled={request_busy} onClick={handle_human_approve}>Approve</button>
                    <button className="secondary-button" type="button" disabled={request_busy} onClick={handle_human_deny}>Deny</button>
                </div>}
                {has_active_run and <div className="run-actions">
                    {request_busy and <p className="request-feedback" role="status" aria-live="polite">Waiting for the backend response…</p>}
                    <button className="secondary-button" type="button" disabled={request_busy} onClick={handle_refresh}>
                        {refresh_button_label(request_busy, api_error)}
                    </button>
                    {status == "PAUSED" and <button className="advance-button" type="button" disabled={request_busy} onClick={handle_resume}>
                        {request_busy and "Resuming..." or "Resume"}
                    </button>}
                    {status == "RUNNING" or status == "RECOVERING" and <button className="secondary-button" type="button" disabled={request_busy} onClick={handle_pause}>
                        {request_busy and "Pausing..." or "Pause"}
                    </button>}
                    {not terminal and <button className="advance-button" type="button" disabled={advance_button_disabled(status, request_busy)} onClick={handle_advance}>
                        Advance one step
                    </button>}
                </div>}
            </article>

            <Metrics
                metrics={metrics_data}
                error={metrics_error}
                loading={metrics_loading}
                onRefresh={handle_metrics_refresh}
            />
        </section>

        <ExecutionGraph
            nodes={graph_nodes}
            edges={graph_edges}
            steps={steps}
            events={events}
            recoveries={recoveries}
            run_id={run_id_label}
            run_status={status}
            error={graph_error}
            loading={graph_loading}
            has_run={has_active_run}
        />

        <section className="lower-grid" aria-label="Run details">
            <RecoveryTimeline
                events={events}
                recoveries={recoveries}
                has_run={has_active_run}
                policy={policy_data}
                repair_diff={repair_diff_data}
            />

            <article className="panel report-panel">
                <div className="panel-heading">
                    <div>
                        <p className="eyebrow">FINAL OUTPUT</p>
                        <h2>Research report</h2>
                    </div>
                    <span className="report-icon" aria-hidden="true">▤</span>
                </div>
                {if has_report {
                    <div className="report-content" key="report-content">
                        <p className="report-title">{str(final_report_data.get("title", "Verified report"))}</p>
                        <p className="report-summary">{str(final_report_data.get("executive_summary", ""))}</p>
                        <h3>Findings</h3>
                        {for (index, finding) in enumerate(findings) {
                            <p className="report-item" key={str(index)}>{str(finding)}</p>
                        }}
                        <h3>Recommendations</h3>
                        {for (index, recommendation) in enumerate(recommendations) {
                            <p className="report-item" key={"recommendation-" + str(index)}>{str(recommendation)}</p>
                        }}
                        <h3>Source IDs</h3>
                        <label className="field-label" htmlFor="source-drawer-select">Inspect fixture source</label>
                        <select
                            id="source-drawer-select"
                            className="scenario-select"
                            value={source_drawer_id}
                            onChange={handle_source_select_change}
                        >
                            <option value="">Choose source ID…</option>
                            {for (index, sid) in enumerate(source_ids) {
                                <option value={sid} key={str(index)}>{sid}</option>
                            }}
                        </select>
                        {selected_fixture is not None and <div className="source-drawer">
                            <p><strong>{str(selected_fixture.get("title", ""))}</strong></p>
                            <p>Tier: {str(selected_fixture.get("tier", ""))}</p>
                            <p>{str(selected_fixture.get("excerpt", ""))}</p>
                        </div>}
                        <span className="model-mode">{model_mode}</span>
                    </div>
                } else {
                    <div className="report-empty" key="report-empty">
                        <p>Your verified report will appear here.</p>
                        <span>Source references and findings will come from the completed run.</span>
                    </div>
                }}
            </article>
        </section>

        <footer className="footer-note">
            <span className="footer-indicator"></span>
            {footer_connection_note(has_active_run)}
        </footer>
    </main>;
}
