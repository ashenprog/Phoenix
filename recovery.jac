"""PHOENIX recovery policy — classify, select, execute (bounded)."""

import time;

import from ai { compose_report }
import from models { Scenario }
import from tools {
    check_report,
    extract_key_points,
    reset_fault_state,
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

glob _BENCHMARK_SCENARIOS: list[Scenario] = [
    Scenario.NORMAL,
    Scenario.PRIMARY_503,
    Scenario.TEMP_TIMEOUT,
    Scenario.INVALID_OUTPUT,
    Scenario.PERMISSION_DENIED,
];

glob _BENCHMARK_LIMITATIONS: list[str] = [
    "Controlled fixture faults only; not production reliability evidence.",
    "Tiny deterministic sample (five scenarios); no statistical significance.",
    "No concurrency or load stress testing.",
];

def _benchmark_findings(records: list[dict[str, any]]) -> list[str] {
    out: list[str] = [];
    for rec in records {
        excerpt = str(rec.get("excerpt", "")).strip();
        if len(excerpt) > 0 {
            out.append(excerpt);
        }
    }
    if len(out) == 0 {
        out = ["[FIXTURE] benchmark finding."];
    }
    return out;
}

def _benchmark_source_ids(records: list[dict[str, any]]) -> list[str] {
    ids: list[str] = [];
    for rec in records {
        sid = rec.get("source_id", "");
        if isinstance(sid, str) and len(sid) > 0 and sid not in ids {
            ids.append(sid);
        }
    }
    return ids;
}

def _benchmark_report_ok(run_id: str, records: list[dict[str, any]]) -> bool {
    composed = compose_report(
        "benchmark fixture task",
        _benchmark_findings(records),
        _benchmark_source_ids(records),
    );
    report_doc = composed["report"];
    return check_report(run_id, Scenario.NORMAL, report_doc)["ok"];
}

def _benchmark_first_attempt(
    run_id: str,
    scenario: Scenario,
) -> dict[str, any] {
    tool_calls = 0;
    records: list[dict[str, any]] = [];
    if scenario == Scenario.INVALID_OUTPUT {
        setup = retrieve_primary(f"{run_id}-setup", Scenario.NORMAL);
        tool_calls += 1;
        if setup.get("ok") {
            maybe = setup["data"].get("records", []);
            if isinstance(maybe, list) {
                records = maybe;
            }
        }
        first = extract_key_points(run_id, scenario, records);
        tool_calls += 1;
        return {
            "tool_result": first,
            "tool_calls": tool_calls,
            "records": records,
        };
    }
    first = retrieve_primary(run_id, scenario);
    tool_calls = 1;
    if first.get("ok") {
        maybe = first["data"].get("records", []);
        if isinstance(maybe, list) {
            records = maybe;
        }
    }
    return {
        "tool_result": first,
        "tool_calls": tool_calls,
        "records": records,
    };
}

def _benchmark_needs_recovery(tool_result: dict[str, any]) -> bool {
    if not tool_result.get("ok") {
        return True;
    }
    return classify_failure(tool_result) == "INVALID_OUTPUT";
}

def _records_after_recovery(
    recovery_out: dict[str, any],
    prior_records: list[dict[str, any]],
) -> list[dict[str, any]] {
    action = recovery_out.get("action_result", {});
    if isinstance(action, dict) and action.get("ok") {
        data = action.get("data", {});
        if isinstance(data, dict) {
            recs = data.get("records", []);
            if isinstance(recs, list) and len(recs) > 0 {
                return recs;
            }
        }
    }
    return prior_records;
}

def _baseline_one(run_id: str, scenario: Scenario) -> dict[str, any] {
    reset_fault_state(run_id);
    attempt = _benchmark_first_attempt(run_id, scenario);
    tool_calls = int(attempt["tool_calls"]);
    records = attempt["records"];
    tool_result = attempt["tool_result"];
    failures = 0;
    if _benchmark_needs_recovery(tool_result) {
        failures = 1;
        return {
            "completed": False,
            "failures": failures,
            "tool_calls": tool_calls,
            "repeated_tool_calls": max(0, tool_calls - 1),
        };
    }
    completed = _benchmark_report_ok(run_id, records);
    return {
        "completed": completed,
        "failures": failures,
        "tool_calls": tool_calls,
        "repeated_tool_calls": max(0, tool_calls - 1),
    };
}

def _phoenix_one(run_id: str, scenario: Scenario) -> dict[str, any] {
    reset_fault_state(run_id);
    attempt = _benchmark_first_attempt(run_id, scenario);
    tool_calls = int(attempt["tool_calls"]);
    records = attempt["records"];
    tool_result = attempt["tool_result"];
    failures = 0;
    recoveries_verified = 0;
    recovery_attempts = 0;
    if not _benchmark_needs_recovery(tool_result) {
        completed = _benchmark_report_ok(run_id, records);
        return {
            "completed": completed,
            "failures": failures,
            "recoveries_verified": recoveries_verified,
            "recovery_attempts": recovery_attempts,
            "tool_calls": tool_calls,
            "repeated_tool_calls": max(0, tool_calls - 1),
        };
    }
    failures = 1;
    category = classify_failure(tool_result);
    pick = select_strategy(
        category,
        {"retries_this_step": 0, "recoveries_this_run": 0},
    );
    recovery_attempts = 1;
    recovery_out = execute_recovery(
        {
            "run_id": run_id,
            "scenario": scenario,
            "records": records,
            "category": category,
            "reason": pick["reason"],
            "requires_approval": pick["requires_approval"],
            "attempt_count": 1,
        },
        pick["strategy"],
    );
    if recovery_out.get("executed") {
        tool_calls += 1;
    }
    if recovery_out.get("verification_status") == "VERIFIED" {
        recoveries_verified = 1;
        records = _records_after_recovery(recovery_out, records);
    } else {
        return {
            "completed": False,
            "failures": failures,
            "recoveries_verified": recoveries_verified,
            "recovery_attempts": recovery_attempts,
            "tool_calls": tool_calls,
            "repeated_tool_calls": max(0, tool_calls - 1),
        };
    }
    completed = _benchmark_report_ok(run_id, records);
    return {
        "completed": completed,
        "failures": failures,
        "recoveries_verified": recoveries_verified,
        "recovery_attempts": recovery_attempts,
        "tool_calls": tool_calls,
        "repeated_tool_calls": max(0, tool_calls - 1),
    };
}

def run_reliability_benchmark -> dict[str, any] {
    started = time.time();
    baseline_completed = 0;
    phoenix_completed = 0;
    failures_detected = 0;
    recoveries_verified = 0;
    recovery_attempts = 0;
    repeated_tool_calls = 0;
    permission_baseline_done = False;
    permission_phoenix_done = False;
    for scenario in _BENCHMARK_SCENARIOS {
        sid = str(scenario);
        base = _baseline_one(f"bench-base-{sid}", scenario);
        if base["completed"] {
            baseline_completed += 1;
        }
        failures_detected += int(base["failures"]);
        repeated_tool_calls += int(base["repeated_tool_calls"]);
        if scenario == Scenario.PERMISSION_DENIED {
            permission_baseline_done = base["completed"];
        }
        phx = _phoenix_one(f"bench-phx-{sid}", scenario);
        if phx["completed"] {
            phoenix_completed += 1;
        }
        failures_detected += int(phx["failures"]);
        recoveries_verified += int(phx["recoveries_verified"]);
        recovery_attempts += int(phx["recovery_attempts"]);
        repeated_tool_calls += int(phx["repeated_tool_calls"]);
        if scenario == Scenario.PERMISSION_DENIED {
            permission_phoenix_done = phx["completed"];
        }
    }
    total_runs = len(_BENCHMARK_SCENARIOS) * 2;
    successful_reports = baseline_completed + phoenix_completed;
    elapsed_ms = int((time.time() - started) * 1000);
    return {
        "total_runs": total_runs,
        "successful_reports": successful_reports,
        "failures_detected": failures_detected,
        "recoveries_verified": recoveries_verified,
        "recovery_attempts": recovery_attempts,
        "repeated_tool_calls": repeated_tool_calls,
        "elapsed_ms": elapsed_ms,
        "baseline_completed": baseline_completed,
        "phoenix_completed": phoenix_completed,
        "baseline_vs_phoenix": {
            "baseline_completed": baseline_completed,
            "phoenix_completed": phoenix_completed,
        },
        "completion_rate_baseline": baseline_completed / len(_BENCHMARK_SCENARIOS),
        "completion_rate_phoenix": phoenix_completed / len(_BENCHMARK_SCENARIOS),
        "limitations": _BENCHMARK_LIMITATIONS,
        "permission_denied_completed": {
            "baseline": permission_baseline_done,
            "phoenix": permission_phoenix_done,
        },
    };
}
