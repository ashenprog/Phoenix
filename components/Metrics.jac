def _metric_value(metrics: dict[str, any] | None, key: str) -> str {
    if metrics is None or key not in metrics {
        return "—";
    }
    value = metrics.get(key);
    if value is None or str(value) == "undefined" or str(value) == "None" {
        if key == "average_latency_ms" {
            return "Not measured";
        }
        return "—";
    }
    return str(value);
}

def:pub Metrics(
    metrics: dict[str, any] | None,
    error: str,
    loading: bool,
    onRefresh: Callable[[], None],
) -> JsxElement {
    def handle_refresh(_e: MouseEvent) {
        onRefresh();
    }

    has_baseline: bool = False;
    baseline_completed = "—";
    phoenix_completed = "—";
    has_test_runs = False;
    if metrics is not None {
        has_test_runs = int(metrics.get("total_runs", 0)) > 0;
        baseline = metrics.get("baseline_vs_phoenix");
        if baseline {
            has_baseline = True;
            baseline_completed = str(baseline.get("baseline_completed", "—"));
            phoenix_completed = str(baseline.get("phoenix_completed", "—"));
        }
    }
    latency = _metric_value(metrics, "average_latency_ms");
    if latency != "Not measured" and latency != "—" {
        latency = latency + " ms";
    }

    return <article className="panel metrics-panel" aria-labelledby="metrics-title">
        <div className="panel-heading">
            <div>
                <p className="eyebrow">RECORDED RESULTS</p>
                <h2 id="metrics-title">Run metrics</h2>
            </div>
            <span className="metric-icon" aria-hidden="true">↗</span>
        </div>
        {error and <p className="form-error" role="alert" key="metrics-error">{error}</p>}
        {if metrics is None {
            <div className="empty-state metrics-empty-state" key="metrics-empty">
                <p>{loading and "Loading recorded metrics..." or (error and "Metrics are unavailable." or "No test runs yet")}</p>
                <span>Values are requested from the backend; no sample metrics are shown.</span>
            </div>
        } elif not has_test_runs {
            <div className="empty-state metrics-empty-state" key="metrics-no-runs">
                <p>No test runs yet</p>
                <span>Recorded run metrics will appear here after a task is started.</span>
            </div>
        } else {
            <dl className="metrics-grid" key="metrics-grid">
                <div className="metric-tile" key="total-runs"><dt>Total test runs</dt><dd>{_metric_value(metrics, "total_runs")}</dd></div>
                <div className="metric-tile" key="completed-runs"><dt>Completed tasks</dt><dd>{_metric_value(metrics, "completed_runs")}</dd></div>
                <div className="metric-tile" key="failures-detected"><dt>Total failures</dt><dd>{_metric_value(metrics, "failures_detected")}</dd></div>
                <div className="metric-tile" key="verified-recoveries"><dt>Successful recoveries</dt><dd>{_metric_value(metrics, "recoveries_verified")}</dd></div>
                <div className="metric-tile" key="average-latency"><dt>Average recorded latency</dt><dd>{latency}</dd></div>
            </dl>
        }}
        {has_baseline and has_test_runs and <div className="baseline-race" key="baseline-race">
            <h3>Fixture benchmark (5 scenarios)</h3>
            <div className="baseline-race-columns">
                <div className="baseline-column">
                    <p className="eyebrow">Baseline</p>
                    <strong>{baseline_completed}</strong>
                    <span>completed reports (stops on fault)</span>
                </div>
                <div className="baseline-column baseline-column-phoenix">
                    <p className="eyebrow">PHOENIX</p>
                    <strong>{phoenix_completed}</strong>
                    <span>completed reports (bounded recovery)</span>
                </div>
            </div>
            <p className="muted-copy">Counts from the fixture benchmark in recovery.jac, not production data.</p>
        </div>}
        <p className="muted-copy">Metrics are returned from recorded runs only.</p>
        <button className="secondary-button metrics-refresh" type="button" disabled={loading} onClick={handle_refresh}>
            {loading and "Refreshing metrics..." or "Refresh metrics"}
        </button>
    </article>;
}