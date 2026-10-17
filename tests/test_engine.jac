import from engine { advance_run_state }
import from models {
    RecoveryStatus,
    RunStatus,
    Scenario,
    StepStatus,
    create_run,
    delete_run,
    find_run,
    serialize_run,
    update_step,
}

test "two runs do not leak step state" {
    run_a = create_run("prompt A", Scenario.NORMAL);
    run_b = create_run("prompt B", Scenario.PRIMARY_503);
    id_a = run_a.run_id;
    id_b = run_b.run_id;

    update_step(run_a, 0, StepStatus.COMPLETED, output_summary="done");

    loaded_a = find_run(id_a);
    loaded_b = find_run(id_b);
    assert loaded_a is not None;
    assert loaded_b is not None;

    state_a = serialize_run(loaded_a);
    state_b = serialize_run(loaded_b);

    assert id_a != id_b;
    assert state_a["prompt"] == "prompt A";
    assert state_b["prompt"] == "prompt B";
    assert state_a["steps"][0]["status"] == StepStatus.COMPLETED;
    assert state_b["steps"][0]["status"] == StepStatus.PENDING;
    assert len(state_a["steps"]) == 5;
    assert len(state_b["steps"]) == 5;
    assert state_a["checkpoint"]["completed_step"] == -1;
    assert len(state_a["events"]) == 0;
    assert len(state_a["recoveries"]) == 0;

    delete_run(loaded_a);
    delete_run(loaded_b);
}

test "NORMAL run completes in five advances" {
    run = create_run("Research AI reliability", Scenario.NORMAL);
    state = serialize_run(run);
    for _ in range(5) {
        state = advance_run_state(run);
    }
    assert state["status"] == RunStatus.COMPLETED;
    assert state["checkpoint"]["completed_step"] == 4;
    assert state["final_report"] is not None;
    assert "fixture-primary-1" in state["final_report"]["source_ids"];
    before = serialize_run(run);
    after = advance_run_state(run);
    assert after["checkpoint"]["completed_step"] == before["checkpoint"]["completed_step"];
    assert after["steps"][4]["status"] == StepStatus.COMPLETED;
    delete_run(run);
}

test "PRIMARY_503 recovers and completes" {
    run = create_run("503 demo", Scenario.PRIMARY_503);
    advance_run_state(run);
    failed = advance_run_state(run);
    assert failed["steps"][1]["status"] == StepStatus.FAILED;
    assert failed["status"] == RunStatus.RECOVERING;
    recovered = advance_run_state(run);
    assert recovered["steps"][1]["status"] == StepStatus.COMPLETED;
    assert recovered["status"] == RunStatus.RUNNING;
    has_fallback = False;
    for rec in recovered["recoveries"] {
        if rec["strategy"] == "FALLBACK_TOOL" and rec["status"] == RecoveryStatus.VERIFIED {
            has_fallback = True;
        }
    }
    assert has_fallback;
    state = recovered;
    for _ in range(3) {
        state = advance_run_state(run);
    }
    assert state["status"] == RunStatus.COMPLETED;
    delete_run(run);
}

test "TEMP_TIMEOUT recovers and completes" {
    run = create_run("timeout demo", Scenario.TEMP_TIMEOUT);
    advance_run_state(run);
    failed = advance_run_state(run);
    assert failed["steps"][1]["status"] == StepStatus.FAILED;
    assert failed["status"] == RunStatus.RECOVERING;
    recovered = advance_run_state(run);
    assert recovered["steps"][1]["status"] == StepStatus.COMPLETED;
    assert recovered["status"] == RunStatus.RUNNING;
    has_retry = False;
    for rec in recovered["recoveries"] {
        if rec["strategy"] == "RETRY" and rec["status"] == RecoveryStatus.VERIFIED {
            has_retry = True;
        }
    }
    assert has_retry;
    state = recovered;
    for _ in range(3) {
        state = advance_run_state(run);
    }
    assert state["status"] == RunStatus.COMPLETED;
    delete_run(run);
}

test "INVALID_OUTPUT recovers and completes" {
    run = create_run("invalid demo", Scenario.INVALID_OUTPUT);
    advance_run_state(run);
    advance_run_state(run);
    advance_run_state(run);
    failed = advance_run_state(run);
    assert failed["steps"][3]["status"] == StepStatus.FAILED;
    assert failed["status"] == RunStatus.RECOVERING;
    recovered = advance_run_state(run);
    assert recovered["steps"][3]["status"] == StepStatus.COMPLETED;
    assert recovered["status"] == RunStatus.RUNNING;
    has_repair = False;
    for rec in recovered["recoveries"] {
        if rec["strategy"] == "REPAIR_OUTPUT" and rec["status"] == RecoveryStatus.VERIFIED {
            has_repair = True;
        }
    }
    assert has_repair;
    state = advance_run_state(run);
    assert state["status"] == RunStatus.COMPLETED;
    delete_run(run);
}

test "PERMISSION_DENIED stops for human approval" {
    run = create_run("permission demo", Scenario.PERMISSION_DENIED);
    advance_run_state(run);
    failed = advance_run_state(run);
    assert failed["steps"][1]["status"] == StepStatus.FAILED;
    assert failed["status"] == RunStatus.RECOVERING;
    human = advance_run_state(run);
    assert human["status"] == RunStatus.NEEDS_HUMAN;
    assert human["steps"][1]["status"] == StepStatus.FAILED;
    has_human = False;
    for rec in human["recoveries"] {
        if rec["strategy"] == "HUMAN_APPROVAL" {
            has_human = True;
        }
    }
    assert has_human;
    delete_run(run);
}
