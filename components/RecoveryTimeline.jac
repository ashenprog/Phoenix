def _event_title(event: dict[str, any]) -> str {
    event_type = str(event.get("type", "EVENT"));
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
        return "Recovery executed";
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

def:pub RecoveryTimeline(
    events: list[dict[str, any]],
    recoveries: list[dict[str, any]],
    has_run: bool,
) -> JsxElement {
    return <article className="panel timeline-panel">
        <div className="panel-heading">
            <div>
                <p className="eyebrow">AUDIT TRAIL</p>
                <h2>Event timeline</h2>
            </div>
            <span className="event-count">{str(len(events))} events</span>
        </div>
        {if len(events) == 0 {
            <div className="empty-state" key="timeline-empty">
                <span className="empty-state-mark" aria-hidden="true">↳</span>
                <p>{has_run and "No events recorded yet" or "No events to display"}</p>
                <span>Backend events appear here in chronological response order.</span>
            </div>
        } else {
            <ol className="event-list" key="event-list">
                {for (index, event) in enumerate(events) {
                    event_type = str(event.get("type", "EVENT")).lower();
                    <li className={"event-item event-" + event_type} key={str(index)}>
                        <span className="event-marker" aria-hidden="true"></span>
                        <div className="event-content">
                            <div className="event-title-row">
                                <strong>{_event_title(event)}</strong>
                                {event.get("timestamp") and <time>{str(event.get("timestamp"))}</time>}
                            </div>
                            <p>{event.get("detail") and str(event.get("detail")) or str(event.get("category", ""))}</p>
                            {event.get("simulated") and <span className="simulated-tag">SIMULATED</span>}
                        </div>
                    </li>
                }}
            </ol>
        }}
        {if len(recoveries) > 0 {
            <div className="recovery-records" key="recovery-records">
                <h3>Recorded recovery attempts</h3>
                {for (index, recovery) in enumerate(recoveries) {
                    state = str(recovery.get("status", "UNKNOWN")).lower();
                    <div className={"recovery-record recovery-state-" + state} key={str(index)}>
                        <strong>{str(recovery.get("strategy", "Recovery"))}</strong>
                        <span>{str(recovery.get("status", "UNKNOWN"))}</span>
                        <p>{str(recovery.get("reason", ""))}</p>
                    </div>
                }}
            </div>
        }}
        <p className="muted-copy timeline-note">
            Only events and recovery attempts returned by the backend are listed; no timeline events are synthesized in the browser.
        </p>
    </article>;
}