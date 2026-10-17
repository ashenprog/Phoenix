"""PHOENIX — full-stack entry (server + client)."""

import from api {
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

def:pub phoenix_health -> dict[str, any] {
    return {
        "ok": True,
        "service": "phoenix",
        "contract_version": "1",
    };
}

import ".styles.css";
import from .components.Dashboard { Dashboard }

def:pub app -> JsxElement {
    return <Dashboard />;
}
