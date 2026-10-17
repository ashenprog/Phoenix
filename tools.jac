"""PHOENIX demo tools — fixture sources and per-run simulated faults."""

import json;
import from pathlib { Path }
import from models { Scenario }

glob FAULT_LEDGER: dict[str, dict[str, int]] = {};

def reset_fault_state(run_id: str) {
    if run_id in FAULT_LEDGER {
        del FAULT_LEDGER[run_id];
    }
}

def _ledger(run_id: str) -> dict[str, int] {
    if run_id not in FAULT_LEDGER {
        FAULT_LEDGER[run_id] = {};
    }
    return FAULT_LEDGER[run_id];
}

def _attempt(run_id: str, key: str) -> int {
    led = _ledger(run_id);
    count = led.get(key, 0);
    led[key] = count + 1;
    return count;
}

def _project_root -> Path {
    return Path(__file__).resolve().parent;
}

def _load_sources -> list[dict[str, any]] {
    path = _project_root() / "data" / "sources.json";
    raw = json.loads(path.read_text(encoding="utf-8"));
    return raw["sources"];
}

def _source_index -> dict[str, dict[str, any]] {
    idx: dict[str, dict[str, any]] = {};
    for item in _load_sources() {
        idx[item["source_id"]] = item;
    }
    return idx;
}

def _sources_for_tier(tier: str) -> list[dict[str, any]] {
    out: list[dict[str, any]] = [];
    for src in _load_sources() {
        if src.get("tier") == tier {
            out.append(
                {
                    "source_id": src["source_id"],
                    "title": src["title"],
                    "url": src["url"],
                    "excerpt": src["excerpt"],
                    "topic_tags": src["topic_tags"],
                }
            );
        }
    }
    return out;
}

def _tool_ok(
    data: dict[str, any],
    tool_name: str,
    source_mode: str,
) -> dict[str, any] {
    return {
        "ok": True,
        "data": data,
        "error_code": None,
        "error_message": None,
        "tool_name": tool_name,
        "source_mode": source_mode,
    };
}

def _tool_err(
    error_code: str,
    error_message: str,
    tool_name: str,
    source_mode: str,
) -> dict[str, any] {
    return {
        "ok": False,
        "data": {},
        "error_code": error_code,
        "error_message": error_message,
        "tool_name": tool_name,
        "source_mode": source_mode,
    };
}

def retrieve_primary(run_id: str, scenario: Scenario) -> dict[str, any] {
    tool = "retrieve_primary";
    mode = "PRIMARY";
    if scenario == Scenario.PERMISSION_DENIED {
        return _tool_err(
            "PERMISSION_DENIED",
            "Simulated permission denied on primary retrieve (fixture).",
            tool,
            mode,
        );
    }
    if scenario == Scenario.PRIMARY_503 {
        return _tool_err(
            "SERVICE_UNAVAILABLE",
            "Simulated primary service unavailable (503) — fixture fault.",
            tool,
            mode,
        );
    }
    if scenario == Scenario.TEMP_TIMEOUT {
        if _attempt(run_id, "retrieve_primary_timeout") == 0 {
            return _tool_err(
                "TIMEOUT",
                "Simulated transient timeout on primary retrieve (fixture).",
                tool,
                mode,
            );
        }
    }
    records = _sources_for_tier("primary");
    return _tool_ok({"records": records, "simulated": True}, tool, mode);
}

def retrieve_backup(run_id: str, scenario: Scenario) -> dict[str, any] {
    _ = run_id;
    tool = "retrieve_backup";
    mode = "BACKUP";
    if scenario == Scenario.PERMISSION_DENIED {
        return _tool_err(
            "PERMISSION_DENIED",
            "Simulated permission denied on backup retrieve (fixture).",
            tool,
            mode,
        );
    }
    records = _sources_for_tier("backup");
    return _tool_ok({"records": records, "simulated": True}, tool, mode);
}

def validate_sources(
    run_id: str,
    scenario: Scenario,
    records: list[dict[str, any]],
) -> dict[str, any] {
    tool = "validate_sources";
    _ = run_id;
    _ = scenario;
    idx = _source_index();
    for rec in records {
        sid = rec.get("source_id", "");
        if sid not in idx {
            return _tool_err(
                "INVALID_OUTPUT",
                "Simulated invalid source record in fixture validation.",
                tool,
                "FIXTURE",
            );
        }
    }
    return _tool_ok({"valid": True, "count": len(records)}, tool, "FIXTURE");
}

def extract_key_points(
    run_id: str,
    scenario: Scenario,
    records: list[dict[str, any]],
) -> dict[str, any] {
    tool = "extract_key_points";
    if scenario == Scenario.INVALID_OUTPUT {
        if _attempt(run_id, "extract_invalid") == 0 {
            return _tool_ok(
                {"points": "not-a-list", "simulated_bad_schema": True},
                tool,
                "FIXTURE",
            );
        }
    }
    points: list[str] = [];
    for rec in records {
        excerpt = str(rec.get("excerpt", ""));
        if len(excerpt) > 0 {
            points.append(excerpt);
        }
    }
    return _tool_ok({"points": points}, tool, "FIXTURE");
}

def check_report(
    run_id: str,
    scenario: Scenario,
    report_doc: dict[str, any],
) -> dict[str, any] {
    tool = "check_report";
    _ = run_id;
    _ = scenario;
    idx = _source_index();
    required = [
        "title",
        "executive_summary",
        "findings",
        "recommendations",
        "source_ids",
    ];
    for key in required {
        if key not in report_doc {
            return _tool_err(
                "INVALID_OUTPUT",
                f"Report missing required field: {key}",
                tool,
                "FIXTURE",
            );
        }
    }
    source_ids = report_doc["source_ids"];
    if not isinstance(source_ids, list) {
        return _tool_err(
            "INVALID_OUTPUT",
            "Report source_ids must be a list.",
            tool,
            "FIXTURE",
        );
    }
    for sid in source_ids {
        if sid not in idx {
            return _tool_err(
                "INVALID_OUTPUT",
                f"Report cites unknown fixture source_id: {sid}",
                tool,
                "FIXTURE",
            );
        }
    }
    return _tool_ok({"verified": True}, tool, "FIXTURE");
}

test "fixture tools and per-run fault isolation" {
    normal = retrieve_primary("run-normal", Scenario.NORMAL);
    assert normal["ok"];
    assert len(normal["data"]["records"]) >= 1;

    fail503 = retrieve_primary("run-503", Scenario.PRIMARY_503);
    assert not fail503["ok"];
    assert fail503["error_code"] == "SERVICE_UNAVAILABLE";
    ok_backup = retrieve_backup("run-503", Scenario.PRIMARY_503);
    assert ok_backup["ok"];
    assert ok_backup["source_mode"] == "BACKUP";

    run_a = "run-timeout-a";
    run_b = "run-timeout-b";
    reset_fault_state(run_a);
    reset_fault_state(run_b);
    t_a1 = retrieve_primary(run_a, Scenario.TEMP_TIMEOUT);
    assert not t_a1["ok"] and t_a1["error_code"] == "TIMEOUT";
    t_a2 = retrieve_primary(run_a, Scenario.TEMP_TIMEOUT);
    assert t_a2["ok"];
    t_b1 = retrieve_primary(run_b, Scenario.TEMP_TIMEOUT);
    assert not t_b1["ok"] and t_b1["error_code"] == "TIMEOUT";

    run_inv = "run-invalid";
    reset_fault_state(run_inv);
    recs = _sources_for_tier("primary");
    bad = extract_key_points(run_inv, Scenario.INVALID_OUTPUT, recs);
    assert bad["ok"];
    assert bad["data"].get("simulated_bad_schema");
    good = extract_key_points(run_inv, Scenario.INVALID_OUTPUT, recs);
    assert good["ok"];
    assert isinstance(good["data"]["points"], list);

    perm_p = retrieve_primary("run-perm", Scenario.PERMISSION_DENIED);
    perm_b = retrieve_backup("run-perm", Scenario.PERMISSION_DENIED);
    assert not perm_p["ok"] and perm_p["error_code"] == "PERMISSION_DENIED";
    assert not perm_b["ok"] and perm_b["error_code"] == "PERMISSION_DENIED";

    report_doc = {
        "title": "Fixture report",
        "executive_summary": "Demo summary.",
        "findings": ["Finding one."],
        "recommendations": ["Use bounded retries."],
        "source_ids": ["fixture-primary-1"],
    };
    verified = check_report("run-report", Scenario.NORMAL, report_doc);
    assert verified["ok"];
}
