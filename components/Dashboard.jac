import from .graph_helpers {
    advance_button_disabled,
    benchmark_caption,
    connection_label,
    demo_ready_message,
    event_css_class,
    event_title,
    footer_connection_note,
    graph_node_class,
    graph_node_subtitle,
    graph_node_title,
    graph_panel_caption,
    metrics_has_data,
    parse_metrics_snapshot,
    progress_caption,
    progress_percent,
    readable_diagnostic,
    recovery_record_heading,
    refresh_button_label,
    report_empty_title,
    rpc_error_message,
    rpcrpc_response_failed,
    rpc_unwrap_payload,
    run_is_terminal,
    status_display,
    step_index_label,
    timeline_empty_title,
    progress_empty_label,
    workflow_step_class,
}
import from ..api {
    advance_run,
    get_metrics,
    get_run,
    get_run_graph,
    pause_run,
    resume_run,
    start_run,
}
import from "@jac/runtime" { __jacClearCache }

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

def:pub Dashboard() -> JsxElement {
    has prompt: str = "";
    has scenario: str = "NORMAL";
    has run_state: dict[str, any] | None = None;
    has graph_nodes: list[dict[str, any]] = [];
    has metrics_snapshot: dict[str, any] | None = None;
    has request_busy: bool = False;
    has api_error: str = "";

    def handle_prompt_change(e: ChangeEvent) {
        prompt = e.target.value;
    }

    def handle_scenario_change(e: ChangeEvent) {
        scenario = e.target.value;
    }

    async def refresh_sidecars(run_id: str) -> None {
        try {
            metrics_resp = await get_metrics();
            if not rpc_response_failed(metrics_resp) {
                metrics_snapshot = rpc_unwrap_payload(metrics_resp);
            }
        } except Exception as err {
            _ = err;
        }
        if len(run_id) == 0 {
            return;
        }
        try {
            graph_resp = await get_run_graph(run_id);
            if not rpc_response_failed(graph_resp) {
                graph_payload = rpc_unwrap_payload(graph_resp);
                nodes_in = graph_payload.get("nodes", []);
                graph_nodes = [];
                if isinstance(nodes_in, list) {
                    for graph_item in nodes_in {
                        graph_nodes.append(graph_item as dict[str, any]);
                    }
                }
            }
        } except Exception as err {
            _ = err;
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
                    await refresh_sidecars(run_id);
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
                await refresh_sidecars(run_id);
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
                await refresh_sidecars(run_id);
            }
        } except Exception as err {
            api_error = readable_diagnostic(f"Could not advance this run: {str(err)}");
        } finally {
            _request_in_flight = False;
            request_busy = False;
        }
    }

    async def handle_pause() -> None {
        if _request_in_flight or len(_active_run_id) == 0 {
            return;
        }
        _request_in_flight = True;
        request_busy = True;
        api_error = "";
        run_id = _active_run_id;
        try {
            response = await pause_run(run_id);
            if rpc_response_failed(response) {
                api_error = readable_diagnostic(rpc_error_message(response));
            } else {
                run_state = rpc_unwrap_payload(response);
                await refresh_sidecars(run_id);
            }
        } except Exception as err {
            api_error = readable_diagnostic(f"Could not pause this run: {str(err)}");
        } finally {
            _request_in_flight = False;
            request_busy = False;
        }
    }

    async def handle_resume() -> None {
        if _request_in_flight or len(_active_run_id) == 0 {
            return;
        }
        _request_in_flight = True;
        request_busy = True;
        api_error = "";
        run_id = _active_run_id;
        try {
            response = await resume_run(run_id);
            if rpc_response_failed(response) {
                api_error = readable_diagnostic(rpc_error_message(response));
            } else {
                run_state = rpc_unwrap_payload(response);
                await refresh_sidecars(run_id);
            }
        } except Exception as err {
            api_error = readable_diagnostic(f"Could not resume this run: {str(err)}");
        } finally {
            _request_in_flight = False;
            request_busy = False;
        }
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
            demo_state = state;
            for _ in range(8) {
                if _recovery_demo_done(demo_state) {
                    break;
                }
                adv = await advance_run(run_id);
                if rpc_response_failed(adv) {
                    api_error = readable_diagnostic(rpc_error_message(adv));
                    break;
                }
                demo_state = rpc_unwrap_payload(adv);
                run_state = demo_state;
                if demo_state.get("status") == "COMPLETED" {
                    break;
                }
            }
            await refresh_sidecars(run_id);
        } except Exception as err {
            api_error = readable_diagnostic(
                f"Could not play the recovery demo: {str(err)}"
            );
        } finally {
            _request_in_flight = False;
            request_busy = False;
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
    metrics_total = 0;
    metrics_completed = 0;
    metrics_failures = 0;
    metrics_verified = 0;
    baseline_completed = 0;
    phoenix_completed = 0;
    has_metrics = False;
    if metrics_snapshot is not None {
        has_metrics = True;
        parsed = parse_metrics_snapshot(metrics_snapshot);
        metrics_total = parsed["total_runs"];
        metrics_completed = parsed["completed_runs"];
        metrics_failures = parsed["failures_detected"];
        metrics_verified = parsed["recoveries_verified"];
        baseline_completed = parsed["baseline_completed"];
        phoenix_completed = parsed["phoenix_completed"];
    }
    show_graph_nodes = len(graph_nodes) > 0;

    return
        <main className="phoenix-app">
            <header className="topbar">
                <a className="brand" href="#" aria-label="Phoenix home">
                    <span className="brand-mark" aria-hidden="true">P</span>
                    <span>PHOENIX</span>
                </a>
                <div className="topbar-meta">
                    <span className="environment-pill">
                        <span className="status-dot"></span>
                        Local workspace
                    </span>
                    <span className="connection-state">
                        {connection_label(has_active_run)}
                    </span>
                </div>
            </header>
            <section className="welcome-row" aria-labelledby="page-title">
                <div>
                    <p className="eyebrow">RELIABLE RESEARCH WORKFLOWS</p>
                    <h1 id="page-title">Run monitor</h1>
                    <p className="page-description">
                        Start a task and follow its progress, recovery events, and verified result.
                    </p>
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
                    <label className="field-label" htmlFor="task-prompt">
                        What should PHOENIX research?
                    </label>
                    <textarea
                        id="task-prompt"
                        className="task-input"
                        placeholder="For example: Research how teams improve AI agent reliability"
                        value={prompt}
                        onChange={handle_prompt_change}
                        rows={3}
                    />
                    <div className="form-actions">
                        <div className="scenario-field">
                            <label className="field-label" htmlFor="scenario-select">
                                Test scenario
                            </label>
                            <select
                                id="scenario-select"
                                className="scenario-select"
                                value={scenario}
                                onChange={handle_scenario_change}
                            >
                                <option value="NORMAL">Normal run</option>
                                <option value="PRIMARY_503">Simulated API 503</option>
                                <option value="TEMP_TIMEOUT">Simulated timeout</option>
                                <option value="INVALID_OUTPUT">
                                    Simulated invalid output
                                </option>
                                <option value="PERMISSION_DENIED">
                                    Simulated permission denied
                                </option>
                            </select>
                        </div>
                        <button
                            className="start-button"
                            type="button"
                            disabled={request_busy or len(prompt.strip()) == 0}
                            onClick={handle_start}
                        >
                            <span aria-hidden="true">▶</span>
                            {request_busy and "Working..." or "Start run"}
                        </button>
                        <button
                            className="demo-button"
                            type="button"
                            disabled={request_busy}
                            onClick={handle_play_503}
                        >
                            Play 503 recovery
                        </button>
                    </div>
                    {api_error
                        and not has_active_run
                        and <p className="form-error" role="alert">{api_error}</p>}
                    {not api_error
                        and <p className="form-note" role="status">
                            {demo_ready_message(
                                _recovery_demo_done(
                                    run_state if run_state is not None else {"steps": [], "recoveries": []}
                                )
                            )}
                        </p>}
                </div>
            </section>
            <section className="overview-grid" aria-label="Run overview">
                <article className="panel progress-panel">
                    <div className="panel-heading">
                        <div>
                            <p className="eyebrow">CURRENT RUN</p>
                            <h2>Progress</h2>
                        </div>
                        <span className="empty-tag">
                            {has_active_run and run_id_label or "No run yet"}
                        </span>
                    </div>
                    <div className="progress-summary">
                        <span className="progress-number">
                            {has_active_run and str(completed_count) or "—"}
                        </span>
                        <span className="progress-copy">
                            {has_active_run
                                and f"of {step_total} steps completed"
                                or "steps completed"}
                        </span>
                    </div>
                    <div
                        className="progress-track"
                        role="progressbar"
                        aria-label="Completed workflow steps"
                        aria-valuemin={0}
                        aria-valuemax={step_total}
                        aria-valuenow={completed_count}
                    >
                        <span style={{"width": f"{progress_pct}%"}}></span>
                    </div>
                    <p className="muted-copy">
                        {has_active_run
                            and progress_caption(current_step, status)
                            or "Run progress will appear here after a task starts."}
                    </p>
                    {api_error
                        and has_active_run
                        and <p className="form-error" role="alert">{api_error}</p>}
                    {has_active_run
                        and <div className="run-actions">
                            <button
                                className="secondary-button"
                                type="button"
                                disabled={request_busy}
                                onClick={handle_refresh}
                            >
                                {refresh_button_label(request_busy, api_error)}
                            </button>
                            {status == "RUNNING" or status == "RECOVERING"
                                and <button
                                    className="secondary-button"
                                    type="button"
                                    disabled={request_busy}
                                    onClick={handle_pause}
                                >
                                    Pause
                                </button>}
                            {status == "PAUSED"
                                and <button
                                    className="secondary-button"
                                    type="button"
                                    disabled={request_busy}
                                    onClick={handle_resume}
                                >
                                    Resume
                                </button>}
                            {not terminal
                                and <button
                                    className="advance-button"
                                    type="button"
                                    disabled={advance_button_disabled(status, request_busy)}
                                    onClick={handle_advance}
                                >
                                    Advance one step
                                </button>}
                        </div>}
                </article>
                <article className="panel metrics-panel">
                    <div className="panel-heading">
                        <div>
                            <p className="eyebrow">RECORDED RESULTS</p>
                            <h2>Run metrics</h2>
                        </div>
                        <span className="metric-icon" aria-hidden="true">↗</span>
                    </div>
                    {has_metrics and metrics_has_data(metrics_total)
                        and <div className="metrics-grid" key="metrics-data">
                            <p>
                                <strong>{str(metrics_completed)}</strong> completed runs
                            </p>
                            <p>
                                <strong>{str(metrics_failures)}</strong> failures detected
                            </p>
                            <p>
                                <strong>{str(metrics_verified)}</strong> recoveries verified
                            </p>
                            <p className="muted-copy">
                                {benchmark_caption(baseline_completed, phoenix_completed)}
                            </p>
                        </div>}
                    {not has_metrics or not metrics_has_data(metrics_total)
                        and <p className="metrics-empty">No test runs yet</p>}
                    <p className="muted-copy">
                        Metrics use recorded runs and the fixture benchmark only.
                    </p>
                </article>
            </section>
            <section className="panel graph-panel" aria-labelledby="workflow-title">
                <div className="panel-heading">
                    <div>
                        <p className="eyebrow">EXECUTION VIEW</p>
                        <h2 id="workflow-title">Workflow graph</h2>
                    </div>
                    <span className="graph-caption">
                        {graph_panel_caption(has_active_run, run_id_label)}
                    </span>
                </div>
                <div
                    className="workflow-preview"
                    aria-label="Backend-confirmed workflow steps"
                >
                    {if show_graph_nodes {
                        for (index, graph_item) in enumerate(graph_nodes) {
                            kind = str(graph_item.get("kind", "step"));
                            <div
                                className={graph_node_class(graph_item)}
                                key={"graph-" + str(index)}
                            >
                                <span>{kind.upper()}</span>
                                <strong>{graph_node_title(graph_item)}</strong>
                                <small>{graph_node_subtitle(graph_item)}</small>
                            </div>
                        }
                    } elif has_active_run {
                        for step in steps {
                            <div
                                className={workflow_step_class(
                                    str(step.get("status", "PENDING"))
                                )}
                                key={str(step.get("index", 0))}
                            >
                                <span>{step_index_label(int(step.get("index", 0)))}</span>
                                <strong>{str(step.get("name", "Step"))}</strong>
                                <small>
                                    {status_display(str(step.get("status", "PENDING")))}
                                </small>
                                {step.get("error_summary")
                                    and <small className="step-error">
                                        {str(step.get("error_summary"))}
                                    </small>}
                            </div>
                        }
                    } else {
                        <p className="muted-copy" key="workflow-empty">
                            Start a run to display backend-confirmed step statuses.
                        </p>
                    } }
                </div>
                {has_active_run
                    and <p className="muted-copy graph-note">
                        Shown statuses come from the latest backend response; the browser does not change step state.
                    </p>}
            </section>
            <section className="lower-grid" aria-label="Run details">
                <article className="panel timeline-panel">
                    <div className="panel-heading">
                        <div>
                            <p className="eyebrow">AUDIT TRAIL</p>
                            <h2>Event timeline</h2>
                        </div>
                        <span className="event-count">{str(len(events))} events</span>
                    </div>
                    {if len(events) == 0 {
                        <div className="empty-state" key="timeline-empty">
                            <span className="empty-state-mark" aria-hidden="true">
                                ↳
                            </span>
                            <p>
                                {has_active_run
                                    and "No events recorded yet"
                                    or "No events to display"}
                            </p>
                            <span>Backend events will appear here in time order.</span>
                        </div>
                    } else {
                        <ol className="event-list" key="event-list">
                            {for (index, event) in enumerate(events) {
                                <li
                                    className={event_css_class(
                                        str(event.get("type", "event"))
                                    )}
                                    key={str(index)}
                                >
                                    <span
                                        className="event-marker"
                                        aria-hidden="true"
                                    ></span>
                                    <div className="event-content">
                                        <div className="event-title-row">
                                            <strong>{event_title(str(event.get("type", "EVENT")))}</strong>
                                            {event.get("timestamp")
                                                and <time>
                                                    {str(event.get("timestamp"))}
                                                </time>}
                                        </div>
                                        <p>
                                            {event.get("detail")
                                                and str(event.get("detail"))
                                                or str(event.get("category", ""))}
                                        </p>
                                        {event.get("simulated")
                                            and <span className="simulated-tag">
                                                SIMULATED
                                            </span>}
                                    </div>
                                </li>
                            }}
                        </ol>
                    } }
                    {if len(recoveries) > 0 {
                        <div className="recovery-records" key="recovery-records">
                            <h3>Recorded recovery attempts</h3>
                            {for (index, recovery) in enumerate(recoveries) {
                                <div className="recovery-record" key={str(index)}>
                                    <strong>
                                        {recovery_record_heading(
                                            str(recovery.get("strategy", "Recovery")),
                                            str(recovery.get("status", "UNKNOWN")),
                                        )}
                                    </strong>
                                    <p>{str(recovery.get("reason", ""))}</p>
                                </div>
                            }}
                        </div>
                    }}
                </article>
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
                            <p className="report-title">
                                {str(final_report_data.get("title", "Verified report"))}
                            </p>
                            <p className="report-summary">
                                {str(final_report_data.get("executive_summary", ""))}
                            </p>
                            <h3>Findings</h3>
                            {for (index, finding) in enumerate(findings) {
                                <p className="report-item" key={str(index)}>
                                    {str(finding)}
                                </p>
                            }}
                            <h3>Recommendations</h3>
                            {for (index, recommendation) in enumerate(
                                recommendations
                            ) {
                                <p
                                    className="report-item"
                                    key={"recommendation-" + str(index)}
                                >
                                    {str(recommendation)}
                                </p>
                            }}
                            <h3>Source IDs</h3>
                            <p className="source-ids">{", ".join(source_ids)}</p>
                            <span className="model-mode">{model_mode}</span>
                        </div>
                    } else {
                        <div className="report-empty" key="report-empty">
                            <p>Your verified report will appear here.</p>
                            <span>
                                Source references and findings will come from the completed run.
                            </span>
                        </div>
                    } }
                </article>
            </section>
            <footer className="footer-note">
                <span className="footer-indicator"></span>
                {footer_connection_note(has_active_run)}
            </footer>
        </main>;
}
