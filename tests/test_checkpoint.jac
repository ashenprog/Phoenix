import from engine { advance_run_state, pause_run_state, resume_run_state }
import from models {
    RunStatus,
    Scenario,
    StepStatus,
    create_run,
    delete_run,
    find_run,
    serialize_run,
}

test "pause and resume preserve completed steps" {
    run = create_run("checkpoint demo", Scenario.NORMAL);
    rid = run.run_id;
    advance_run_state(run);
    advance_run_state(run);
    mid = serialize_run(run);
    summary0 = mid["steps"][0]["output_summary"];
    summary1 = mid["steps"][1]["output_summary"];
    paused = pause_run_state(run);
    assert paused["status"] == RunStatus.PAUSED;
    reloaded = find_run(rid);
    assert reloaded is not None;
    resumed = resume_run_state(reloaded);
    assert resumed["status"] == RunStatus.RUNNING;
    advance_run_state(reloaded);
    final = serialize_run(reloaded);
    assert final["steps"][0]["status"] == StepStatus.COMPLETED;
    assert final["steps"][1]["status"] == StepStatus.COMPLETED;
    assert final["steps"][0]["output_summary"] == summary0;
    assert final["steps"][1]["output_summary"] == summary1;
    delete_run(reloaded);
}
