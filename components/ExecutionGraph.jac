def _graph_title(item: dict[str, any]) -> str {
    kind = str(item.get("kind", "node"));
    if kind == "step" {
        return str(item.get("name", "Workflow step"));
    }
    if kind == "failure" {
        return str(item.get("label", "Failure"));
    }
    if kind == "recovery" {
        return str(item.get("strategy", "Recovery"));
    }
    return kind.replace("_", " ").capitalize();
}

def _graph_status(item: dict[str, any], run_status: str) -> str {
    kind = str(item.get("kind", ""));
    if kind == "failure" {
        return "FAILED";
    }
    if kind == "recovery" {
        if run_status == "NEEDS_HUMAN" {
            return "NEEDS_HUMAN";
        }
        recovery_status = str(item.get("status", "PROPOSED"));
        if recovery_status == "VERIFIED" {
            return "COMPLETED";
        }
        if recovery_status == "FAILED" or recovery_status == "EXHAUSTED" {
            return "FAILED";
        }
        return "RECOVERING";
    }
    return str(item.get("status", "PENDING"));
}

def _graph_node_label(node_id: str, nodes: list[dict[str, any]]) -> str {
    for item in nodes {
        if str(item.get("id", "")) == node_id {
            return _graph_title(item);
        }
    }
    return node_id;
}

def _graph_node_kind(node_id: str, nodes: list[dict[str, any]]) -> str {
    for item in nodes {
        if str(item.get("id", "")) == node_id {
            return str(item.get("kind", ""));
        }
    }
    return "";
}

def _edge_class(graph_link: dict[str, any], nodes: list[dict[str, any]], run_status: str) -> str {
    from_id = str(graph_link.get("from", ""));
    to_id = str(graph_link.get("to", ""));
    from_kind = _graph_node_kind(from_id, nodes);
    to_kind = _graph_node_kind(to_id, nodes);
    if to_kind == "failure" {
        return "graph-edge-failure";
    }
    if from_kind == "failure" or from_kind == "recovery" or to_kind == "recovery" {
        if run_status == "NEEDS_HUMAN" and to_kind == "recovery" {
            return "graph-edge-human";
        }
        if to_kind == "recovery" or from_kind == "failure" {
            return "graph-edge-recovery";
        }
    }
    from_status = "";
    to_status = "";
    for item in nodes {
        if str(item.get("id", "")) == from_id {
            from_status = _graph_status(item, run_status);
        }
        if str(item.get("id", "")) == to_id {
            to_status = _graph_status(item, run_status);
        }
    }
    if from_kind == "step" and to_kind == "step" and from_status == "COMPLETED" and to_status == "COMPLETED" {
        return "graph-edge-completed";
    }
    if from_kind == "recovery" and to_kind == "step" and from_status == "COMPLETED" and to_status == "COMPLETED" {
        return "graph-edge-completed";
    }
    return "graph-edge-pending";
}

def _detail_for_step(graph_item: dict[str, any], steps: list[dict[str, any]]) -> dict[str, any] {
    wanted_index = int(graph_item.get("step_index", -1));
    for step in steps {
        if int(step.get("index", -2)) == wanted_index {
            return step;
        }
    }
    return {};
}

def _detail_for_failure(graph_item: dict[str, any], events: list[dict[str, any]]) -> dict[str, any] {
    wanted_index = int(graph_item.get("step_index", -1));
    wanted_label = str(graph_item.get("label", ""));
    found: dict[str, any] = {};
    for event in events {
        if (
            str(event.get("type", "")) == "FAILURE"
            and int(event.get("step_index", -2)) == wanted_index
            and (len(wanted_label) == 0 or str(event.get("category", "")) == wanted_label)
        ) {
            found = event;
        }
    }
    return found;
}

def _detail_for_recovery(graph_item: dict[str, any], recoveries: list[dict[str, any]]) -> dict[str, any] {
    wanted_strategy = str(graph_item.get("strategy", ""));
    found: dict[str, any] = {};
    for recovery in recoveries {
        if str(recovery.get("strategy", "")) == wanted_strategy {
            found = recovery;
        }
    }
    return found;
}

def:pub ExecutionGraph(
    nodes: list[dict[str, any]],
    edges: list[dict[str, any]],
    steps: list[dict[str, any]],
    events: list[dict[str, any]],
    recoveries: list[dict[str, any]],
    run_id: str,
    run_status: str,
    error: str,
    loading: bool,
    has_run: bool,
) -> JsxElement {
    has selected_node_id: str = "";

    def handle_graph_selection(e: ChangeEvent) {
        selected_node_id = e.target.value;
    }

    selected_node: dict[str, any] = {};
    has_selected_node = False;
    for item in nodes {
        if str(item.get("id", "")) == selected_node_id {
            selected_node = item;
            has_selected_node = True;
        }
    }

    selected_step: dict[str, any] = {};
    selected_failure: dict[str, any] = {};
    selected_recovery: dict[str, any] = {};
    has_selected_step = False;
    has_selected_failure = False;
    has_selected_recovery = False;
    has_selected_step_index = False;
    if has_selected_node {
        selected_kind = str(selected_node.get("kind", ""));
        if selected_kind == "step" {
            selected_step = _detail_for_step(selected_node, steps);
            has_selected_step = True;
            has_selected_step_index = True;
        }
        if selected_kind == "failure" {
            selected_failure = _detail_for_failure(selected_node, events);
            has_selected_failure = True;
            has_selected_step_index = True;
        }
        if selected_kind == "recovery" {
            selected_recovery = _detail_for_recovery(selected_node, recoveries);
            has_selected_recovery = True;
        }
    }

    return <section className="panel graph-panel" aria-labelledby="workflow-title">
        <div className="panel-heading">
            <div>
                <p className="eyebrow">EXECUTION VIEW</p>
                <h2 id="workflow-title">Workflow graph</h2>
            </div>
            <span className="graph-caption">{has_run and "Run " + run_id or "Workflow structure"}</span>
        </div>
        {error and <p className="form-error" role="alert">{error}</p>}
        {if len(nodes) == 0 {
            <div className="empty-state" key="graph-empty">
                <p>{loading and "Loading graph data from the backend..." or (has_run and "No graph data returned for this run." or "Start a run to display backend graph nodes and edges.")}</p>
                <span>The graph uses the latest response from get_run_graph.</span>
            </div>
        } else {
            <div className="graph-layout" key="graph-content">
                <div className="graph-status-legend" aria-label="Node status color legend">
                    <span className="legend-pending">Pending</span>
                    <span className="legend-running">Running</span>
                    <span className="legend-completed">Completed</span>
                    <span className="legend-failed">Failed</span>
                    <span className="legend-recovering">Recovering</span>
                    <span className="legend-human">Needs human</span>
                </div>
                <div className="graph-nodes" aria-label="Selectable backend graph nodes" role="radiogroup">
                    {for graph_item in nodes {
                        kind = str(graph_item.get("kind", "node")).lower();
                        node_id = str(graph_item.get("id", ""));
                        actual_status = str(graph_item.get("status", "PENDING"));
                        visual_status = _graph_status(graph_item, run_status);
                        selected_class = "";
                        if selected_node_id == node_id {
                            selected_class = " graph-node-selected";
                        }
                        status_label = actual_status;
                        if kind == "failure" {
                            status_label = "FAILED";
                        }
                        <label className={"graph-node graph-node-" + kind + " graph-state-" + visual_status.lower() + selected_class} key={node_id}>
                            <input
                                type="radio"
                                name="execution-graph-node"
                                value={node_id}
                                checked={selected_node_id == node_id}
                                onChange={handle_graph_selection}
                            />
                            <span className="graph-node-kind">{kind.replace("_", " ")}</span>
                            <strong>{_graph_title(graph_item)}</strong>
                            <span className="graph-node-status">{status_label}</span>
                            {kind == "recovery" and run_status == "NEEDS_HUMAN" and <small className="graph-run-state">Run needs human action</small>}
                        </label>
                    }}
                </div>
                {len(edges) > 0 and <div className="graph-edges" aria-label="Backend-returned graph connections">
                    <h3>Connections returned by backend</h3>
                    <ol>
                        {for (index, graph_link) in enumerate(edges) {
                            from_id = str(graph_link.get("from", ""));
                            to_id = str(graph_link.get("to", ""));
                            edge_class = _edge_class(graph_link, nodes, run_status);
                            <li className={"graph-edge " + edge_class} key={str(index)}>
                                <span>{_graph_node_label(from_id, nodes)}</span>
                                <span className="graph-edge-arrow" aria-hidden="true">-&gt;</span>
                                <span>{_graph_node_label(to_id, nodes)}</span>
                            </li>
                        }}
                    </ol>
                </div>}
                {has_selected_node and <aside className="graph-node-details" aria-live="polite" key="selected-node-details">
                    <div className="graph-detail-heading">
                        <div>
                            <p className="eyebrow">SELECTED NODE</p>
                            <h3>{_graph_title(selected_node)}</h3>
                        </div>
                        <span className={"graph-detail-status graph-state-" + _graph_status(selected_node, run_status).lower()}>
                            {str(selected_node.get("kind", "")) == "failure" and "FAILED" or (str(selected_node.get("kind", "")) == "recovery" and str(selected_node.get("status", "UNKNOWN")) or str(selected_node.get("status", "UNKNOWN")))}
                        </span>
                    </div>
                    {has_selected_step_index and <p className="graph-detail-line">Step {int(selected_node.get("step_index", 0)) + 1}</p>}
                    {has_selected_step and <div className="graph-detail-copy" key="step-details">
                        <p><strong>Output summary</strong></p>
                        <p>{selected_step.get("output_summary") and str(selected_step.get("output_summary")) or "No output summary returned for this step."}</p>
                        {selected_step.get("error_summary") and <p className="graph-detail-error"><strong>Error:</strong> {str(selected_step.get("error_summary"))}</p>}
                    </div>}
                    {has_selected_failure and <div className="graph-detail-copy graph-detail-error" key="failure-details">
                        <p><strong>{str(selected_failure.get("category", "Failure"))}</strong></p>
                        <p>{selected_failure.get("detail") and str(selected_failure.get("detail")) or "No additional failure detail was returned."}</p>
                        {selected_failure.get("simulated") and <span className="simulated-tag">SIMULATED</span>}
                    </div>}
                    {has_selected_recovery and <div className="graph-detail-copy" key="recovery-details">
                        <p><strong>Recovery: {str(selected_recovery.get("strategy", "Unknown"))} · {str(selected_recovery.get("status", "UNKNOWN"))}</strong></p>
                        <p>{selected_recovery.get("reason") and str(selected_recovery.get("reason")) or "No recovery detail returned."}</p>
                        {run_status == "NEEDS_HUMAN" and <p className="graph-detail-human">Run status: NEEDS HUMAN</p>}
                    </div>}
                </aside>}
            </div>
        }}
        {has_run and <p className="muted-copy graph-note">
            Node states and connections come from backend responses. Select a node for its recorded details.
        </p>}
    </section>;
}
