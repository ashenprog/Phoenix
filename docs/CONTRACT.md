# PHOENIX shared API contract

All three developers agree on this document by minute 45. Field names and response shapes here are the source of truth for backend, UI, and recovery code.

**Authority rule:** The Jac backend owns run state, failures, recovery decisions, checkpoints, and progress. The browser is a monitor and controller only. It must not invent status, failures, recovery, checkpoints, or step completion.

---

## Status enums

### Run status

| Value | Meaning |
|---|---|
| `PENDING` | Run created; not yet executing |
| `RUNNING` | Normal step work in progress |
| `RECOVERING` | A failure occurred; recovery in progress |
| `PAUSED` | User or system paused; checkpoint preserved |
| `NEEDS_HUMAN` | Permission or policy requires human action |
| `COMPLETED` | All steps done; final report verified |
| `STOPPED` | Run halted (error, policy, or user) |

### Step status

| Value | Meaning |
|---|---|
| `PENDING` | Not started |
| `RUNNING` | Currently executing |
| `FAILED` | Step failed; may trigger recovery |
| `COMPLETED` | Step finished successfully |

### Recovery attempt status

| Value | Meaning |
|---|---|
| `PROPOSED` | Strategy selected; not yet executed |
| `RUNNING` | Recovery action executing |
| `VERIFIED` | Action ran and output passed verification |
| `FAILED` | Recovery action or verification failed |
| `EXHAUSTED` | Retry/recovery limits reached for this path |

---

## Workflow steps

Five ordered steps (indices 0–4):

| Index | Name | Purpose |
|---|---|---|
| 0 | Plan | Turn the request into a brief outline |
| 1 | Retrieve | Fetch trusted fixture research sources |
| 2 | Analyze | Validate records and summarize findings |
| 3 | Generate | Create the research report |
| 4 | Verify | Check required sections and source references |

---

## Scenarios

Controlled, **simulated** fault injection. UI and `start_run` use these exact strings:

| Scenario | Behavior |
|---|---|
| `NORMAL` | No injected failure |
| `PRIMARY_503` | Primary retrieve tool fails once (simulated 503); backup allowed |
| `TEMP_TIMEOUT` | One transient timeout, then retry may succeed |
| `INVALID_OUTPUT` | One invalid tool/schema response; repair or re-run |
| `PERMISSION_DENIED` | Safe stop; must not bypass; run → `NEEDS_HUMAN` |

Fault and scenario state are **per run**. No global fault counters shared across runs.

---

## Graph node types

Persistent Jac graph archetypes (Developer 1 implements in `models.jac`):

| Type | Role |
|---|---|
| `TaskRun` | Root run record (`run_id`, prompt, scenario, status, …) |
| `TaskStep` | One of the five steps, linked to its run |
| `FailureEvent` | Recorded failure (category, message, step, simulated flag) |
| `RecoveryAttempt` | Strategy, status, verification, attempt counts |
| `Checkpoint` | Last committed completed step index and snapshot metadata |

---

## Failure categories

Used in `events` and recovery classification (Developer 3 implements mapping in `recovery.jac`):

- `SERVICE_UNAVAILABLE`
- `TIMEOUT`
- `RATE_LIMIT`
- `INVALID_OUTPUT`
- `INTERRUPTED`
- `PERMISSION_DENIED`
- `UNKNOWN_ERROR`

---

## Recovery strategies

Deterministic selection (Developer 3 policy; Developer 1 engine invokes in `RECOVERING` only):

| Category / condition | Strategy |
|---|---|
| Service unavailable (e.g. 503) | `FALLBACK_TOOL` |
| Transient timeout | `RETRY` |
| Invalid schema / output | `REPAIR_OUTPUT` |
| Interruption / pause | `RESUME_CHECKPOINT` |
| Permission denied | `HUMAN_APPROVAL` |
| Unknown | `STOP` |

**Limits:** At most **2 retries per step** and **3 recovery attempts per run**. No infinite loops.

**Success:** A recovery counts as successful only when the strategy **executed** and its output **passed verification** (`VERIFIED`). Logging an attempt is not success. Final run success requires a verified report whose `source_ids` exist in the trusted fixture set (`data/sources.json`).

**Resume:** Completed steps are not re-executed on normal resume; execution continues at the first incomplete step.

---

## Tool result shape

Every tool function (Developer 3, `tools.jac`) returns this structure:

```json
{
  "ok": true,
  "data": {},
  "error_code": null,
  "error_message": null,
  "tool_name": "retrieve_primary",
  "source_mode": "PRIMARY"
}
```

| Field | Type | Notes |
|---|---|---|
| `ok` | boolean | `true` if the tool succeeded |
| `data` | object | Step-specific payload when `ok` |
| `error_code` | string \| null | Machine-readable code when `ok` is false |
| `error_message` | string \| null | Human-readable detail |
| `tool_name` | string | Identifier for audit trail |
| `source_mode` | string | One of: `PRIMARY`, `BACKUP`, `FIXTURE` |

---

## Model mode

Exposed on run state for UI display:

- `LIVE_MODEL` — optional LLM used for report/explanation (`ai.jac`)
- `DETERMINISTIC_FALLBACK` — template/offline report; no API key required

The model must not authorize tools or change retry limits.

---

## Public operations

Implemented as public walkers in `api.jac` (exact Jac syntax per installed `jac guide`). All mutating logic stays in backend modules.

| Operation | Input | Output |
|---|---|---|
| `start_run` | `prompt: string`, `scenario: Scenario` | `run_id` + normalized **RunState** |
| `get_run` | `run_id: string` | **RunState** |
| `advance_run` | `run_id: string` | **RunState** after at most one workflow or recovery transition |
| `pause_run` | `run_id: string` | **RunState** with `status: PAUSED` and checkpoint info |
| `resume_run` | `run_id: string` | **RunState**; resume from first incomplete step |
| `get_run_graph` | `run_id: string` | **RunGraph** (`nodes`, `edges`) |
| `get_metrics` | optional filter (e.g. run id set) | **Metrics** from recorded runs only |
| `reset_demo` | `scope: string` | confirmation; clears demo fixtures only, not all user data |
| `list_runs` | none | array of `{ run_id, status, prompt?, scenario? }` |

UI (Developer 2) calls these walkers only. Do not simulate failures by changing client-side colors or step index without backend confirmation.

---

## RunState (normalized run object)

Single shape returned by `start_run`, `get_run`, `advance_run`, `pause_run`, and `resume_run`:

```json
{
  "run_id": "run-001",
  "prompt": "Research AI reliability",
  "scenario": "PRIMARY_503",
  "status": "RECOVERING",
  "current_step": 1,
  "steps": [
    {
      "index": 0,
      "name": "Plan",
      "status": "COMPLETED",
      "output_summary": null,
      "error_summary": null
    },
    {
      "index": 1,
      "name": "Retrieve",
      "status": "FAILED",
      "output_summary": null,
      "error_summary": "Simulated primary service unavailable (503)"
    }
  ],
  "events": [
    {
      "type": "STEP_STARTED",
      "step_index": 1,
      "timestamp": "ISO-8601",
      "detail": null
    },
    {
      "type": "FAILURE",
      "category": "SERVICE_UNAVAILABLE",
      "step_index": 1,
      "simulated": true,
      "timestamp": "ISO-8601",
      "detail": "PRIMARY_503 scenario"
    }
  ],
  "recoveries": [
    {
      "strategy": "FALLBACK_TOOL",
      "status": "PROPOSED",
      "reason": "Primary retrieve unavailable",
      "attempt_number": 1,
      "requires_approval": false
    }
  ],
  "checkpoint": {
    "completed_step": 0
  },
  "final_report": null,
  "model_mode": "DETERMINISTIC_FALLBACK"
}
```

### Field notes

| Field | Type | Required |
|---|---|---|
| `run_id` | string | yes |
| `prompt` | string | yes |
| `scenario` | Scenario enum | yes |
| `status` | Run status | yes |
| `current_step` | int 0–4 | yes |
| `steps` | StepState[] | yes, length 5 |
| `events` | Event[] | yes, chronological |
| `recoveries` | RecoveryRecord[] | yes |
| `checkpoint` | `{ completed_step: int }` | yes |
| `final_report` | Report \| null | yes |
| `model_mode` | model mode enum | yes |

### Event types (recommended)

`STEP_STARTED`, `STEP_COMPLETED`, `TOOL_EXECUTED`, `FAILURE`, `STRATEGY_SELECTED`, `RECOVERY_STARTED`, `RECOVERY_VERIFIED`, `RUN_PAUSED`, `RUN_RESUMED`, `NEEDS_HUMAN`, `RUN_COMPLETED`

---

## RunGraph

Returned by `get_run_graph`:

```json
{
  "nodes": [
    {
      "id": "step-0",
      "kind": "step",
      "step_index": 0,
      "name": "Plan",
      "status": "COMPLETED"
    },
    {
      "id": "failure-1",
      "kind": "failure",
      "step_index": 1,
      "label": "Simulated 503"
    },
    {
      "id": "recovery-1",
      "kind": "recovery",
      "strategy": "FALLBACK_TOOL",
      "status": "VERIFIED"
    }
  ],
  "edges": [
    { "from": "step-0", "to": "step-1" },
    { "from": "step-1", "to": "failure-1" },
    { "from": "failure-1", "to": "recovery-1" },
    { "from": "recovery-1", "to": "step-1" }
  ]
}
```

Node `status` colors in UI (Developer 2): pending gray, running blue, completed green, failed red, recovering orange, needs-human purple.

---

## Report (final_report)

Present when run reaches `COMPLETED` and verification passes:

```json
{
  "title": "string",
  "executive_summary": "string",
  "findings": ["string"],
  "recommendations": ["string"],
  "source_ids": ["fixture-source-id-1"]
}
```

`source_ids` must reference ids from `data/sources.json` only.

---

## Metrics

Returned by `get_metrics`. Computed from **recorded runs only** — no hardcoded percentages.

```json
{
  "total_runs": 0,
  "completed_runs": 0,
  "failures_detected": 0,
  "recoveries_verified": 0,
  "average_latency_ms": null,
  "baseline_vs_phoenix": {
    "baseline_completed": 0,
    "phoenix_completed": 0
  }
}
```

If no runs exist, UI shows empty state (e.g. “No test runs yet”).

---

## Developer 3 → Developer 1 integration surface

Developer 3 exposes tool and recovery functions; Developer 1 wires them from `engine.jac` only. Developer 3 does not edit `engine.jac` or `api.jac`.

**Expected from `recovery.jac` (names may be adjusted in handoff; shapes must match):**

- `classify_failure(tool_result | error)` → failure category
- `select_strategy(category, attempt_history)` → `{ strategy, reason, requires_approval }`
- `execute_recovery(run_context, strategy)` → updated tool result + verification status

**Expected from `tools.jac`:** step dispatch by step index and scenario, returning the tool result shape above.

Amendments to this contract: propose to Developer 1; do not silently change schemas in owned files.

---

## File ownership

| Path | Owner |
|---|---|
| `main.jac`, `jac.toml`, `models.jac`, `engine.jac`, `api.jac` | Developer 1 |
| `tests/test_engine.jac`, `tests/test_checkpoint.jac` | Developer 1 |
| `docs/CONTRACT.md`, `README.md`, `.gitignore` | Developer 1 |
| `components/*.cl.jac`, `styles.css`, `docs/DEMO.md` | Developer 2 |
| `tools.jac`, `recovery.jac`, `ai.jac`, `data/sources.json`, `tests/test_recovery.jac` | Developer 3 |

**Shared rules**

- `docs/CONTRACT.md`: Developer 1 writes; others suggest amendments to D1.
- `main.jac`: D2 supplies component exports; D1 imports and wires.
- `jac.toml`: D3 requests `byllm` via D1; only D1 changes project config.

---

## Version

Contract draft: hackathon day 1 (Developer 1). Verify public walker syntax against `jac guide` for the installed Jac version when implementing `api.jac`.
