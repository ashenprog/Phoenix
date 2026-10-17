import from models {
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
