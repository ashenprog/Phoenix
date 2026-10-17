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
    if metrics is not None {
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
                <p>{loading and "Loading recorded metrics..." or "Metrics are not available yet."}</p>
                <span>Values are requested from the backend; no sample metrics are shown.</span>
            </div>
        } else {
            <dl className="metrics-grid" key="metrics-grid">
                <div className="metric-tile" key="total-runs"><dt>Total runs</dt><dd>{_metric_value(metrics, "total_runs")}</dd></div>
                <div className="metric-tile" key="completed-runs"><dt>Completed</dt><dd>{_metric_value(metrics, "completed_runs")}</dd></div>
                <div className="metric-tile" key="failures-detected"><dt>Failures detected</dt><dd>{_metric_value(metrics, "failures_detected")}</dd></div>
                <div className="metric-tile" key="verified-recoveries"><dt>Verified recoveries</dt><dd>{_metric_value(metrics, "recoveries_verified")}</dd></div>
                <div className="metric-tile" key="average-latency"><dt>Average latency</dt><dd>{latency}</dd></div>
                {has_baseline and <div className="metric-tile metric-comparison" key="baseline-comparison">
                    <dt>Baseline / PHOENIX completed</dt>
                    <dd>{baseline_completed} / {phoenix_completed}</dd>
                </div>}
            </dl>
        }}
        <p className="muted-copy">Metrics are returned from recorded runs only.</p>
        <button className="secondary-button metrics-refresh" type="button" disabled={loading} onClick={handle_refresh}>
            {loading and "Refreshing metrics..." or "Refresh metrics"}
        </button>
    </article>;
}