"""PHOENIX — full-stack entry (server + client)."""

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
