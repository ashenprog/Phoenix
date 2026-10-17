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
    policy: dict[str, any] | None = None,
    repair_diff: dict[str, any] | None = None,
) -> JsxElement {
    has_policy = policy is not None and len(str(policy.get("strategy", ""))) > 0;
    has_repair = repair_diff is not None;
    policy_category = "—";
    policy_strategy = "—";
    policy_reason = "";
    policy_retries_used = "0";
    policy_retries_left = "0";
    policy_recoveries_used = "0";
    policy_recoveries_left = "0";
    repair_rejected = "—";
    repair_repaired = "—";
    if policy is not None {
        policy_category = str(policy.get("category", "—"));
        policy_strategy = str(policy.get("strategy", "—"));
        policy_reason = str(policy.get("reason", ""));
        policy_retries_used = str(policy.get("retries_used", 0));
        policy_retries_left = str(policy.get("retries_left", 0));
        policy_recoveries_used = str(policy.get("recoveries_used", 0));
        policy_recoveries_left = str(policy.get("recoveries_left", 0));
    }
    if repair_diff is not None {
        if repair_diff.get("rejected") {
            repair_rejected = str(repair_diff.get("rejected"));
        }
        if repair_diff.get("repaired") {
            repair_repaired = str(repair_diff.get("repaired"));
        }
    }
    return <article className="panel timeline-panel">
        <div className="panel-heading">
            <div>
                <p className="eyebrow">AUDIT TRAIL</p>
                <h2>Event timeline</h2>
            </div>
            <span className="event-count">{str(len(events))} events</span>
        </div>
        {has_policy and <div className="policy-card" key="policy-card">
            <h3>Recovery policy</h3>
            <p><strong>Failure category:</strong> {policy_category}</p>
            <p><strong>Selected strategy:</strong> {policy_strategy}</p>
            <p>{policy_reason}</p>
            <p className="policy-limits">
                Retries used: {policy_retries_used} · left: {policy_retries_left}
                {" · "}
                Recoveries used: {policy_recoveries_used} · left: {policy_recoveries_left}
            </p>
        </div>}
        {has_repair and <div className="repair-diff" key="repair-diff">
            <h3>Invalid output repair</h3>
            <div className="repair-columns">
                <div>
                    <p className="eyebrow">Rejected</p>
                    <pre>{repair_rejected}</pre>
                </div>
                <div>
                    <p className="eyebrow">Repaired</p>
                    <pre>{repair_repaired}</pre>
                </div>
            </div>
        </div>}
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