import from ai { compose_report, explain_recovery }
import from models { ModelMode, Scenario }
import from recovery {
    classify_failure,
    execute_recovery,
    run_reliability_benchmark,
    select_strategy,
}
import from tools {
    check_report,
    extract_key_points,
    reset_fault_state,
    retrieve_primary,
    validate_sources,
}

test "recovery policy scenarios and bounds" {
    # PRIMARY_503 -> fallback verified
    run_503 = "recovery-503";
    reset_fault_state(run_503);
    primary_fail = retrieve_primary(run_503, Scenario.PRIMARY_503);
    cat503 = classify_failure(primary_fail);
    assert cat503 == "SERVICE_UNAVAILABLE";
    pick503 = select_strategy(cat503, {"retries_this_step": 0, "recoveries_this_run": 0});
    assert pick503["strategy"] == "FALLBACK_TOOL";
    out503 = execute_recovery(
        {
            "run_id": run_503,
            "scenario": Scenario.PRIMARY_503,
            "records": [],
            "category": cat503,
            "reason": pick503["reason"],
            "requires_approval": pick503["requires_approval"],
        },
        pick503["strategy"],
    );
    assert out503["executed"];
    assert out503["verification_status"] == "VERIFIED";

    # TEMP_TIMEOUT -> retry verified; second run_id still times out first call
    run_ta = "recovery-timeout-a";
    run_tb = "recovery-timeout-b";
    reset_fault_state(run_ta);
    reset_fault_state(run_tb);
    fail_ta = retrieve_primary(run_ta, Scenario.TEMP_TIMEOUT);
    assert classify_failure(fail_ta) == "TIMEOUT";
    pick_ta = select_strategy("TIMEOUT", {"retries_this_step": 0, "recoveries_this_run": 0});
    assert pick_ta["strategy"] == "RETRY";
    out_ta = execute_recovery(
        {
            "run_id": run_ta,
            "scenario": Scenario.TEMP_TIMEOUT,
            "records": [],
            "category": "TIMEOUT",
            "reason": pick_ta["reason"],
            "requires_approval": False,
        },
        pick_ta["strategy"],
    );
    assert out_ta["verification_status"] == "VERIFIED";
    fail_tb = retrieve_primary(run_tb, Scenario.TEMP_TIMEOUT);
    assert not fail_tb["ok"] and fail_tb["error_code"] == "TIMEOUT";

    # INVALID_OUTPUT -> repair verified
    run_inv = "recovery-invalid";
    reset_fault_state(run_inv);
    recs = retrieve_primary("recovery-invalid-setup", Scenario.NORMAL)["data"]["records"];
    bad_extract = extract_key_points(run_inv, Scenario.INVALID_OUTPUT, recs);
    cat_inv = classify_failure(bad_extract);
    assert cat_inv == "INVALID_OUTPUT";
    pick_inv = select_strategy(cat_inv, {"retries_this_step": 0, "recoveries_this_run": 0});
    assert pick_inv["strategy"] == "REPAIR_OUTPUT";
    out_inv = execute_recovery(
        {
            "run_id": run_inv,
            "scenario": Scenario.INVALID_OUTPUT,
            "records": recs,
            "category": cat_inv,
            "reason": pick_inv["reason"],
            "requires_approval": False,
        },
        pick_inv["strategy"],
    );
    assert out_inv["verification_status"] == "VERIFIED";

    # PERMISSION_DENIED -> human approval, no bypass
    run_perm = "recovery-perm";
    reset_fault_state(run_perm);
    perm_fail = retrieve_primary(run_perm, Scenario.PERMISSION_DENIED);
    cat_perm = classify_failure(perm_fail);
    pick_perm = select_strategy(cat_perm, {"retries_this_step": 0, "recoveries_this_run": 0});
    assert pick_perm["strategy"] == "HUMAN_APPROVAL";
    assert pick_perm["requires_approval"];
    out_perm = execute_recovery(
        {
            "run_id": run_perm,
            "scenario": Scenario.PERMISSION_DENIED,
            "records": [],
            "category": cat_perm,
            "reason": pick_perm["reason"],
            "requires_approval": True,
        },
        pick_perm["strategy"],
    );
    assert not out_perm["executed"];
    assert out_perm["verification_status"] != "VERIFIED";

    # Retry cap -> STOP
    pick_stop = select_strategy("TIMEOUT", {"retries_this_step": 2, "recoveries_this_run": 0});
    assert pick_stop["strategy"] == "STOP";
}

test "recovery interleaving isolation and attempt metadata" {
    # NORMAL success — no failure classification needed
    normal = retrieve_primary("recovery-normal-ok", Scenario.NORMAL);
    assert normal["ok"];
    assert classify_failure(normal) == "UNKNOWN_ERROR";

    # Interleaved TEMP_TIMEOUT: A fail, B fail, recover A, recover B
    run_a = "interleave-timeout-a";
    run_b = "interleave-timeout-b";
    reset_fault_state(run_a);
    reset_fault_state(run_b);
    fail_a = retrieve_primary(run_a, Scenario.TEMP_TIMEOUT);
    assert classify_failure(fail_a) == "TIMEOUT";
    fail_b = retrieve_primary(run_b, Scenario.TEMP_TIMEOUT);
    assert not fail_b["ok"] and fail_b["error_code"] == "TIMEOUT";
    pick_a = select_strategy("TIMEOUT", {"retries_this_step": 0, "recoveries_this_run": 0});
    ctx_a = {
        "run_id": run_a,
        "scenario": Scenario.TEMP_TIMEOUT,
        "records": [],
        "category": "TIMEOUT",
        "reason": pick_a["reason"],
        "requires_approval": False,
        "attempt_count": 1,
    };
    out_a = execute_recovery(ctx_a, pick_a["strategy"]);
    assert out_a["verification_status"] == "VERIFIED";
    assert out_a["attempt_count"] == 1;
    pick_b = select_strategy("TIMEOUT", {"retries_this_step": 0, "recoveries_this_run": 0});
    ctx_b = {
        "run_id": run_b,
        "scenario": Scenario.TEMP_TIMEOUT,
        "records": [],
        "category": "TIMEOUT",
        "reason": pick_b["reason"],
        "requires_approval": False,
        "attempt_count": 1,
    };
    out_b = execute_recovery(ctx_b, pick_b["strategy"]);
    assert out_b["verification_status"] == "VERIFIED";
    assert out_b["attempt_count"] == 1;

    # Interleaved PRIMARY_503: both fail primary; fallback each; B primary still fails
    run_503_a = "interleave-503-a";
    run_503_b = "interleave-503-b";
    reset_fault_state(run_503_a);
    reset_fault_state(run_503_b);
    p_fail_a = retrieve_primary(run_503_a, Scenario.PRIMARY_503);
    p_fail_b = retrieve_primary(run_503_b, Scenario.PRIMARY_503);
    assert classify_failure(p_fail_a) == "SERVICE_UNAVAILABLE";
    assert classify_failure(p_fail_b) == "SERVICE_UNAVAILABLE";
    pick_fb_a = select_strategy("SERVICE_UNAVAILABLE", {"retries_this_step": 0, "recoveries_this_run": 0});
    out_fb_a = execute_recovery(
        {
            "run_id": run_503_a,
            "scenario": Scenario.PRIMARY_503,
            "records": [],
            "category": "SERVICE_UNAVAILABLE",
            "reason": pick_fb_a["reason"],
            "requires_approval": False,
            "attempt_count": 1,
        },
        pick_fb_a["strategy"],
    );
    assert out_fb_a["verification_status"] == "VERIFIED";
    still_b = retrieve_primary(run_503_b, Scenario.PRIMARY_503);
    assert not still_b["ok"];
    pick_fb_b = select_strategy("SERVICE_UNAVAILABLE", {"retries_this_step": 0, "recoveries_this_run": 0});
    out_fb_b = execute_recovery(
        {
            "run_id": run_503_b,
            "scenario": Scenario.PRIMARY_503,
            "records": [],
            "category": "SERVICE_UNAVAILABLE",
            "reason": pick_fb_b["reason"],
            "requires_approval": False,
            "attempt_count": 1,
        },
        pick_fb_b["strategy"],
    );
    assert out_fb_b["verification_status"] == "VERIFIED";

    # Malformed validate_sources -> INVALID_OUTPUT -> REPAIR with real records
    run_val = "interleave-validate";
    reset_fault_state(run_val);
    good_recs = retrieve_primary("interleave-validate-setup", Scenario.NORMAL)["data"]["records"];
    bad_recs = [{"source_id": "not-a-fixture-id", "excerpt": "bad"}];
    val_fail = validate_sources(run_val, Scenario.NORMAL, bad_recs);
    assert not val_fail["ok"];
    cat_val = classify_failure(val_fail);
    assert cat_val == "INVALID_OUTPUT";
    pick_rep = select_strategy(cat_val, {"retries_this_step": 0, "recoveries_this_run": 0});
    assert pick_rep["strategy"] == "REPAIR_OUTPUT";
    out_rep = execute_recovery(
        {
            "run_id": run_val,
            "scenario": Scenario.NORMAL,
            "records": good_recs,
            "category": cat_val,
            "reason": pick_rep["reason"],
            "requires_approval": False,
            "attempt_count": 2,
        },
        pick_rep["strategy"],
    );
    assert out_rep["executed"];
    assert out_rep["verification_status"] == "VERIFIED";
    assert out_rep["attempt_count"] == 2;

    # Run-wide recovery cap and retry exhaustion -> STOP via execute_recovery
    pick_run_cap = select_strategy("SERVICE_UNAVAILABLE", {"retries_this_step": 0, "recoveries_this_run": 3});
    assert pick_run_cap["strategy"] == "STOP";
    out_run_cap = execute_recovery(
        {
            "run_id": "interleave-cap",
            "scenario": Scenario.PRIMARY_503,
            "records": [],
            "category": "SERVICE_UNAVAILABLE",
            "reason": pick_run_cap["reason"],
            "requires_approval": False,
            "attempt_count": 3,
        },
        pick_run_cap["strategy"],
    );
    assert not out_run_cap["executed"];
    assert out_run_cap["verification_status"] == "EXHAUSTED";
    assert out_run_cap["verification_status"] != "VERIFIED";
    assert out_run_cap["attempt_count"] == 3;

    pick_retry_cap = select_strategy("TIMEOUT", {"retries_this_step": 2, "recoveries_this_run": 0});
    assert pick_retry_cap["strategy"] == "STOP";
    out_retry_cap = execute_recovery(
        {
            "run_id": "interleave-retry-cap",
            "scenario": Scenario.TEMP_TIMEOUT,
            "records": [],
            "category": "TIMEOUT",
            "reason": pick_retry_cap["reason"],
            "requires_approval": False,
            "attempt_count": 2,
        },
        pick_retry_cap["strategy"],
    );
    assert not out_retry_cap["executed"];
    assert out_retry_cap["verification_status"] == "EXHAUSTED";
    assert out_retry_cap["attempt_count"] == 2;
}

test "ai deterministic report and recovery explanation" {
    composed = compose_report(
        "agent reliability",
        ["Fixture finding one."],
        ["fixture-primary-1", "not-a-real-fixture-id"],
    );
    assert composed["model_mode"] == ModelMode.DETERMINISTIC_FALLBACK;
    report_doc = composed["report"];
    assert "fixture-primary-1" in report_doc["source_ids"];
    assert "not-a-real-fixture-id" not in report_doc["source_ids"];
    assert check_report("ai-test", Scenario.NORMAL, report_doc)["ok"];

    explained = explain_recovery(
        "SERVICE_UNAVAILABLE",
        "FALLBACK_TOOL",
        "Primary tool unavailable; use approved backup.",
    );
    assert explained["model_mode"] == ModelMode.DETERMINISTIC_FALLBACK;
    assert explained["model_mode"] != ModelMode.LIVE_MODEL;
    assert "FALLBACK_TOOL" in explained["text"];
}

test "reliability benchmark is deterministic and honest" {
    first = run_reliability_benchmark();
    second = run_reliability_benchmark();
    keys = [
        "total_runs",
        "successful_reports",
        "failures_detected",
        "recoveries_verified",
        "recovery_attempts",
        "repeated_tool_calls",
        "baseline_completed",
        "phoenix_completed",
    ];
    for key in keys {
        assert first[key] == second[key];
    }
    assert first["total_runs"] == 10;
    assert first["phoenix_completed"] > first["baseline_completed"];
    assert len(first["limitations"]) > 0;
    assert first["elapsed_ms"] >= 0;
    perm = first["permission_denied_completed"];
    assert not perm["baseline"] or not perm["phoenix"];
    assert first["baseline_vs_phoenix"]["phoenix_completed"] == first["phoenix_completed"];
}
