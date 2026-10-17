"""PHOENIX persistent task graph — matches docs/CONTRACT.md."""

import uuid;

enum RunStatus: str {
    PENDING = "PENDING",
    RUNNING = "RUNNING",
    RECOVERING = "RECOVERING",
    PAUSED = "PAUSED",
    NEEDS_HUMAN = "NEEDS_HUMAN",
    COMPLETED = "COMPLETED",
    STOPPED = "STOPPED",
}

enum StepStatus: str {
    PENDING = "PENDING",
    RUNNING = "RUNNING",
    FAILED = "FAILED",
    COMPLETED = "COMPLETED",
}

enum RecoveryStatus: str {
    PROPOSED = "PROPOSED",
    RUNNING = "RUNNING",
    VERIFIED = "VERIFIED",
    FAILED = "FAILED",
    EXHAUSTED = "EXHAUSTED",
}

enum Scenario: str {
    NORMAL = "NORMAL",
    PRIMARY_503 = "PRIMARY_503",
    TEMP_TIMEOUT = "TEMP_TIMEOUT",
    INVALID_OUTPUT = "INVALID_OUTPUT",
    PERMISSION_DENIED = "PERMISSION_DENIED",
}

enum ModelMode: str {
    DETERMINISTIC_FALLBACK = "DETERMINISTIC_FALLBACK",
    LIVE_MODEL = "LIVE_MODEL",
}

glob STEP_NAMES: list[str] = ["Plan", "Retrieve", "Analyze", "Generate", "Verify"];

node TaskRun {
    has run_id: str,
        prompt: str,
        scenario: Scenario,
        status: RunStatus = RunStatus.PENDING,
        current_step: int = 0,
        model_mode: ModelMode = ModelMode.DETERMINISTIC_FALLBACK,
        final_report: dict[str, any] | None = None;
}

node TaskStep {
    has index: int,
        name: str,
        status: StepStatus = StepStatus.PENDING,
        output_summary: str | None = None,
        error_summary: str | None = None;
}

node FailureEvent {
    has event_type: str,
        category: str,
        step_index: int,
        simulated: bool,
        timestamp: str,
        detail: str | None = None;
}

node RecoveryAttempt {
    has strategy: str,
        status: RecoveryStatus,
        reason: str,
        attempt_number: int,
        requires_approval: bool;
}

node Checkpoint {
    has completed_step: int = -1;
}

edge HasStep: TaskRun --> TaskStep {}
edge HasEvent: TaskRun --> FailureEvent {}
edge HasRecovery: TaskRun --> RecoveryAttempt {}
edge HasCheckpoint: TaskRun --> Checkpoint {}

def create_run(prompt: str, scenario: Scenario) -> TaskRun {
    run = TaskRun(
        run_id="run-" + str(uuid.uuid4()),
        prompt=prompt,
        scenario=scenario,
    );
    root ++> run;
    checkpoint = Checkpoint(completed_step=-1);
    run +>:HasCheckpoint():+> checkpoint;
    for i in range(len(STEP_NAMES)) {
        step = TaskStep(
            index=i,
            name=STEP_NAMES[i],
            status=StepStatus.PENDING,
        );
        run +>:HasStep():+> step;
    }
    return run;
}

def find_run(run_id: str) -> TaskRun | None {
    for run in [root -->][?:TaskRun] {
        if run.run_id == run_id {
            return run;
        }
    }
    return None;
}

def list_steps(run: TaskRun) -> list[TaskStep] {
    steps = [run ->:HasStep:->][?:TaskStep];
    steps.sort(key=lambda (s: TaskStep) { s.index; });
    return steps;
}

def update_step(
    run: TaskRun,
    index: int,
    status: StepStatus,
    output_summary: str | None = None,
    error_summary: str | None = None,
) -> None {
    for step in list_steps(run) {
        if step.index == index {
            step.status = status;
            step.output_summary = output_summary;
            step.error_summary = error_summary;
            return;
        }
    }
}

def _checkpoint_for(run: TaskRun) -> Checkpoint | None {
    cps = [run ->:HasCheckpoint:->][?:Checkpoint];
    if len(cps) > 0 {
        return cps[0];
    }
    return None;
}

def _events_for(run: TaskRun) -> list[FailureEvent] {
    return [run ->:HasEvent:->][?:FailureEvent];
}

def _recoveries_for(run: TaskRun) -> list[RecoveryAttempt] {
    return [run ->:HasRecovery:->][?:RecoveryAttempt];
}

def serialize_run(run: TaskRun) -> dict[str, any] {
    steps_out: list[dict[str, any]] = [];
    for step in list_steps(run) {
        steps_out.append(
            {
                "index": step.index,
                "name": step.name,
                "status": step.status,
                "output_summary": step.output_summary,
                "error_summary": step.error_summary,
            }
        );
    }
    events_out: list[dict[str, any]] = [];
    for ev in _events_for(run) {
        events_out.append(
            {
                "type": ev.event_type,
                "category": ev.category,
                "step_index": ev.step_index,
                "simulated": ev.simulated,
                "timestamp": ev.timestamp,
                "detail": ev.detail,
            }
        );
    }
    recoveries_out: list[dict[str, any]] = [];
    for rec in _recoveries_for(run) {
        recoveries_out.append(
            {
                "strategy": rec.strategy,
                "status": rec.status,
                "reason": rec.reason,
                "attempt_number": rec.attempt_number,
                "requires_approval": rec.requires_approval,
            }
        );
    }
    cp = _checkpoint_for(run);
    completed = -1;
    if cp is not None {
        completed = cp.completed_step;
    }
    return {
        "run_id": run.run_id,
        "prompt": run.prompt,
        "scenario": run.scenario,
        "status": run.status,
        "current_step": run.current_step,
        "steps": steps_out,
        "events": events_out,
        "recoveries": recoveries_out,
        "checkpoint": {"completed_step": completed},
        "final_report": run.final_report,
        "model_mode": run.model_mode,
    };
}

def delete_run(run: TaskRun) -> None {
    del run;
}
