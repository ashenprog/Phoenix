def:pub Dashboard() -> JsxElement {
    has prompt: str = "";
    has scenario: str = "NORMAL";

    def handle_prompt_change(e: ChangeEvent) {
        prompt = e.target.value;
    }

    def handle_scenario_change(e: ChangeEvent) {
        scenario = e.target.value;
    }

    return <main className="phoenix-app">
        <header className="topbar">
            <a className="brand" href="#" aria-label="Phoenix home">
                <span className="brand-mark" aria-hidden="true">P</span>
                <span>PHOENIX</span>
            </a>
            <div className="topbar-meta">
                <span className="environment-pill"><span className="status-dot"></span>Local workspace</span>
                <span className="connection-state">Backend not connected</span>
            </div>
        </header>

        <section className="welcome-row" aria-labelledby="page-title">
            <div>
                <p className="eyebrow">RELIABLE RESEARCH WORKFLOWS</p>
                <h1 id="page-title">Run monitor</h1>
                <p className="page-description">Start a task and follow its progress, recovery events, and verified result.</p>
            </div>
            <div className="run-status">
                <span className="status-dot status-dot-muted"></span>
                Waiting for a run
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
                    <div className="scenario-field">
                        <label className="field-label" htmlFor="scenario-select">Test scenario</label>
                        <select
                            id="scenario-select"
                            className="scenario-select"
                            value={scenario}
                            onChange={handle_scenario_change}
                        >
                            <option value="NORMAL">Normal run</option>
                            <option value="PRIMARY_503">Simulated API 503</option>
                            <option value="TEMP_TIMEOUT">Simulated timeout</option>
                            <option value="INVALID_OUTPUT">Simulated invalid output</option>
                            <option value="PERMISSION_DENIED">Simulated permission denied</option>
                        </select>
                    </div>
                    <button className="start-button" type="button" disabled={True}>
                        <span aria-hidden="true">▶</span>
                        Start run
                    </button>
                </div>
                <p className="form-note" role="status">
                    Run controls will be enabled when the backend API is connected.
                </p>
            </div>
        </section>

        <section className="overview-grid" aria-label="Run overview">
            <article className="panel progress-panel">
                <div className="panel-heading">
                    <div>
                        <p className="eyebrow">CURRENT RUN</p>
                        <h2>Progress</h2>
                    </div>
                    <span className="empty-tag">No run yet</span>
                </div>
                <div className="progress-summary">
                    <span className="progress-number">—</span>
                    <span className="progress-copy">steps completed</span>
                </div>
                <div className="progress-track" aria-label="No progress yet">
                    <span></span>
                </div>
                <p className="muted-copy">Run progress will appear here after a task starts.</p>
            </article>

            <article className="panel metrics-panel">
                <div className="panel-heading">
                    <div>
                        <p className="eyebrow">RECORDED RESULTS</p>
                        <h2>Run metrics</h2>
                    </div>
                    <span className="metric-icon" aria-hidden="true">↗</span>
                </div>
                <p className="metrics-empty">No test runs yet</p>
                <p className="muted-copy">Metrics will use recorded runs only.</p>
            </article>
        </section>

        <section className="panel graph-panel" aria-labelledby="workflow-title">
            <div className="panel-heading">
                <div>
                    <p className="eyebrow">EXECUTION VIEW</p>
                    <h2 id="workflow-title">Workflow graph</h2>
                </div>
                <span className="graph-caption">Workflow structure · not a live run</span>
            </div>
            <div className="workflow-preview" aria-label="Workflow stages, not current run status">
                <div className="workflow-step"><span>01</span><strong>Plan</strong></div>
                <span className="workflow-connector" aria-hidden="true"></span>
                <div className="workflow-step"><span>02</span><strong>Retrieve</strong></div>
                <span className="workflow-connector" aria-hidden="true"></span>
                <div className="workflow-step"><span>03</span><strong>Analyze</strong></div>
                <span className="workflow-connector" aria-hidden="true"></span>
                <div className="workflow-step"><span>04</span><strong>Generate</strong></div>
                <span className="workflow-connector" aria-hidden="true"></span>
                <div className="workflow-step"><span>05</span><strong>Verify</strong></div>
            </div>
            <p className="muted-copy graph-note">Live statuses and recovery branches will appear when run graph data is available.</p>
        </section>

        <section className="lower-grid" aria-label="Run details">
            <article className="panel timeline-panel">
                <div className="panel-heading">
                    <div>
                        <p className="eyebrow">AUDIT TRAIL</p>
                        <h2>Event timeline</h2>
                    </div>
                    <span className="event-count">0 events</span>
                </div>
                <div className="empty-state">
                    <span className="empty-state-mark" aria-hidden="true">↳</span>
                    <p>No events to display</p>
                    <span>Backend events will appear here in time order.</span>
                </div>
            </article>

            <article className="panel report-panel">
                <div className="panel-heading">
                    <div>
                        <p className="eyebrow">FINAL OUTPUT</p>
                        <h2>Research report</h2>
                    </div>
                    <span className="report-icon" aria-hidden="true">▤</span>
                </div>
                <div className="report-empty">
                    <p>Your verified report will appear here.</p>
                    <span>Source references and findings will come from the completed run.</span>
                </div>
            </article>
        </section>

        <footer className="footer-note">
            <span className="footer-indicator"></span>
            Waiting for backend integration · No demo data is being shown
        </footer>
    </main>;
}