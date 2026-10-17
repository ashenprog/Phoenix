"""PHOENIX recovery policy — classify, select, execute (bounded)."""

import from models { Scenario }
import from tools {
    extract_key_points,
    retrieve_backup,
    retrieve_primary,
}

glob MAX_RETRIES_PER_STEP: int = 2;
glob MAX_RECOVERIES_PER_RUN: int = 3;

def classify_failure(tool_result: dict[str, any]) -> str {
    if tool_result.get("ok") {
        data = tool_result.get("data", {});
        if isinstance(data, dict) and data.get("simulated_bad_schema") {
            return "INVALID_OUTPUT";
        }
        return "UNKNOWN_ERROR";
    }
    code = tool_result.get("error_code", "");
    known = [
        "SERVICE_UNAVAILABLE",
        "TIMEOUT",
        "RATE_LIMIT",
        "INVALID_OUTPUT",
        "INTERRUPTED",
        "PERMISSION_DENIED",
    ];
    if code in known {
        return code;
    }
    return "UNKNOWN_ERROR";
}

def select_strategy(
    category: str,
    attempt_history: dict[str, any],
) -> dict[str, any] {
    retries = int(attempt_history.get("retries_this_step", 0));
    recoveries = int(attempt_history.get("recoveries_this_run", 0));
    if recoveries >= MAX_RECOVERIES_PER_RUN {
        return {
            "strategy": "STOP",
            "reason": "Recovery attempt limit reached for this run.",
            "requires_approval": False,
        };
    }
    if category == "SERVICE_UNAVAILABLE" {
        return {
            "strategy": "FALLBACK_TOOL",
            "reason": "Primary tool unavailable; use approved backup.",
            "requires_approval": False,
        };
    }
    if category == "TIMEOUT" or category == "RATE_LIMIT" {
        if retries < MAX_RETRIES_PER_STEP {
            return {
                "strategy": "RETRY",
                "reason": "Transient failure; bounded retry.",
                "requires_approval": False,
            };
        }
        return {
            "strategy": "STOP",
            "reason": "Retry limit reached for this step.",
            "requires_approval": False,
        };
    }
    if category == "INVALID_OUTPUT" {
        return {
            "strategy": "REPAIR_OUTPUT",
            "reason": "Invalid tool output; repair and re-run.",
            "requires_approval": False,
        };
    }
    if category == "INTERRUPTED" {
        return {
            "strategy": "RESUME_CHECKPOINT",
            "reason": "Run interrupted; resume from checkpoint.",
            "requires_approval": False,
        };
    }
    if category == "PERMISSION_DENIED" {
        return {
            "strategy": "HUMAN_APPROVAL",
            "reason": "Permission denied; human action required.",
            "requires_approval": True,
        };
    }
    return {
        "strategy": "STOP",
        "reason": "Unknown or unsupported failure category.",
        "requires_approval": False,
    };
}

def _verify_backup(action_result: dict[str, any]) -> bool {
    if not action_result.get("ok") {
        return False;
    }
    data = action_result.get("data", {});
    records = data.get("records", []) if isinstance(data, dict) else [];
    return isinstance(records, list) and len(records) > 0;
}

def _verify_primary(action_result: dict[str, any]) -> bool {
    return bool(action_result.get("ok"));
}

def _verify_repair(action_result: dict[str, any]) -> bool {
    if not action_result.get("ok") {
        return False;
    }
    data = action_result.get("data", {});
    if not isinstance(data, dict) {
        return False;
    }
    points = data.get("points");
    return isinstance(points, list);
}

def execute_recovery(
    run_context: dict[str, any],
    strategy: str,
) -> dict[str, any] {
    run_id = str(run_context.get("run_id", ""));
    scenario = run_context.get("scenario", Scenario.NORMAL);
    records = run_context.get("records", []);
    if not isinstance(records, list) {
        records = [];
    }
    category = str(run_context.get("category", "UNKNOWN_ERROR"));
    reason = str(run_context.get("reason", "Recovery action."));
    requires_approval = bool(run_context.get("requires_approval", False));
    attempt_count = int(run_context.get("attempt_count", 0));

    if strategy == "STOP" {
        return {
            "strategy": strategy,
            "reason": reason,
            "requires_approval": requires_approval,
            "executed": False,
            "verification_status": "EXHAUSTED",
            "action_result": {},
            "category": category,
            "attempt_count": attempt_count,
        };
    }
    if strategy == "HUMAN_APPROVAL" {
        return {
            "strategy": strategy,
            "reason": reason,
            "requires_approval": True,
            "executed": False,
            "verification_status": "PROPOSED",
            "action_result": {},
            "category": category,
            "attempt_count": attempt_count,
        };
    }
    if strategy == "RESUME_CHECKPOINT" {
        return {
            "strategy": strategy,
            "reason": reason,
            "requires_approval": False,
            "executed": False,
            "verification_status": "PROPOSED",
            "action_result": {},
            "category": category,
            "attempt_count": attempt_count,
        };
    }

    action_result: dict[str, any] = {};
    verified = False;
    if strategy == "FALLBACK_TOOL" {
        action_result = retrieve_backup(run_id, scenario);
        verified = _verify_backup(action_result);
    } elif strategy == "RETRY" {
        action_result = retrieve_primary(run_id, scenario);
        verified = _verify_primary(action_result);
    } elif strategy == "REPAIR_OUTPUT" {
        action_result = extract_key_points(run_id, scenario, records);
        verified = _verify_repair(action_result);
    } else {
        return {
            "strategy": "STOP",
            "reason": f"Unsupported strategy: {strategy}",
            "requires_approval": False,
            "executed": False,
            "verification_status": "EXHAUSTED",
            "action_result": {},
            "category": category,
            "attempt_count": attempt_count,
        };
    }

    status = "VERIFIED" if verified else "FAILED";
    return {
        "strategy": strategy,
        "reason": reason,
        "requires_approval": requires_approval,
        "executed": True,
        "verification_status": status,
        "action_result": action_result,
        "category": category,
        "attempt_count": attempt_count,
    };
}
