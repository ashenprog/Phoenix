import from .graph_helpers {
    advance_button_disabled,
    connection_label,
    demo_ready_message,
    footer_connection_note,
    progress_caption,
    progress_percent,
    readable_diagnostic,
    refresh_button_label,
    rpc_error_message,
    rpc_response_failed,
    rpc_unwrap_payload,
    run_is_terminal,
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
    }

    async can with entry {
        if not _request_in_flight {
            _request_in_flight = True;
            metrics_loading = True;
            request_busy = True;
            try {
                await refresh_metrics_data();
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

    return <main className="phoenix-app">
        <header className="topbar">
            <a className="brand" href="#" aria-label="Phoenix home">
                <span className="brand-mark" aria-hidden="true">P</span>
                <span>PHOENIX</span>
            </a>
            <div className="topbar-meta">
                <span className="environment-pill"><span className="status-dot"></span>Local workspace</span>
                <span className="connection-state">{connection_label(has_active_run)}</span>
            </div>
        </header>

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
                </div>
                {api_error and not has_active_run and <p className="form-error" role="alert">{api_error}</p>}
                {not api_error and <p className="form-note" role="status">
                    {demo_ready_message(demo_done)}
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
                {api_error and has_active_run and <p className="form-error" role="alert">{api_error}</p>}
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
            <RecoveryTimeline events={events} recoveries={recoveries} has_run={has_active_run} />

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
                        <p className="source-ids">{", ".join(source_ids)}</p>
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
