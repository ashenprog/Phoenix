import from models { Scenario }
import from recovery {
    classify_failure,
    execute_recovery,
    select_strategy,
}
import from tools {
    extract_key_points,
    reset_fault_state,
    retrieve_primary,
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
