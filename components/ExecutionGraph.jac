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

def _graph_detail(item: dict[str, any]) -> str {
    kind = str(item.get("kind", ""));
    if kind == "step" {
        return str(item.get("status", "PENDING")).replace("_", " ");
    }
    if kind == "recovery" {
        return str(item.get("status", "UNKNOWN")).replace("_", " ");
    }
    if kind == "failure" {
        return "Step " + str(int(item.get("step_index", 0)) + 1);
    }
    return str(item.get("status", "")).replace("_", " ");
}

def _graph_node_label(node_id: str, nodes: list[dict[str, any]]) -> str {
    for item in nodes {
        if str(item.get("id", "")) == node_id {
            return _graph_title(item);
        }
    }
    return node_id;
}

def:pub ExecutionGraph(
    nodes: list[dict[str, any]],
    edges: list[dict[str, any]],
    run_id: str,
    error: str,
    has_run: bool,
) -> JsxElement {
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
                <p>{has_run and "No graph data returned for this run." or "Start a run to display backend graph nodes and edges."}</p>
                <span>The graph uses the latest response from get_run_graph.</span>
            </div>
        } else {
            <div className="graph-layout" key="graph-content">
                <div className="graph-nodes" aria-label="Backend graph nodes">
                    {for graph_item in nodes {
                        kind = str(graph_item.get("kind", "node")).lower();
                        state = str(graph_item.get("status", "pending")).lower();
                        node_id = str(graph_item.get("id", ""));
                        <article className={"graph-node graph-node-" + kind + " graph-state-" + state} key={node_id}>
                            <span className="graph-node-kind">{kind.replace("_", " ")}</span>
                            <strong>{_graph_title(graph_item)}</strong>
                            <small>{_graph_detail(graph_item)}</small>
                            {graph_item.get("step_index") is not None and <small>Step {int(graph_item.get("step_index", 0)) + 1}</small>}
                        </article>
                    }}
                </div>
                {len(edges) > 0 and <div className="graph-edges" aria-label="Backend graph edges">
                    <h3>Connections</h3>
                    <ol>
                        {for (index, edge) in enumerate(edges) {
                            from_id = str(edge.get("from", ""));
                            to_id = str(edge.get("to", ""));
                            <li key={str(index)}>
                                <span>{_graph_node_label(from_id, nodes)}</span>
                                <span className="graph-edge-arrow" aria-hidden="true">-&gt;</span>
                                <span>{_graph_node_label(to_id, nodes)}</span>
                            </li>
                        }}
                    </ol>
                </div>}
            </div>
        }}
        {has_run and <p className="muted-copy graph-note">
            Nodes and connections come directly from the backend graph response.
        </p>}
    </section>;
}