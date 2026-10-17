# PHOENIX contract

Integration contract for the PHOENIX Jac reliability layer. This is a supported-failure prototype. It is not a universal self-repairing runtime.

The graph is the source of truth. The demo must run with no network and no model. Live AI is optional.

Observed git branch: `coreDev`. The mission text said to record `development`. The branch checked out in this workspace is `coreDev`.

Installed CLI, recorded exactly:

```text
jac 0.37.25  (Linux x86_64)
```

Guides actually read for this contract:

- `jac-scaffold` sections `always-do-this-before-scaffolding`, `project-kinds-and-what-each-scaffolds`, `pitfalls`, `post-scaffold-checklist`
- `jac-sv-persistence` sections `query-patterns`, `pitfalls`
- `jac guide reference/persistence` (bundled persistence reference)
- `jac-fullstack-patterns` (serve-command note)
- `community/breaking-changes` sections `jac-run-absorbs-jac-start-and-jac-dev-deploying-is-jac-scale-deploy-8596-unreleased` and `all-placement-spellings-removed-svclna-markers-the-svjaccljac-suffixes-and-the-variant-directive-7772-jaclang-035`

## A. Architecture

One Jac web app. Client code lives in client components (`.jac` files whose placement the compiler infers, or a module pin). Server code is walkers on a root-reachable graph. Phoenix does not add a React app, FastAPI, Express, LangGraph, or Postgres of its own. Jac's embedded server and embedded Postgres are Jac runtime services. They are not part of Phoenix.

Flow:

1. Browser.
2. Public walkers.
3. Execution walker.
4. Tools and schema checks.
5. Persistent graph.

Each public request performs at most one normal step or one recovery transition, validates, commits, and returns the run view. The UI renders that view. It does not animate progress on a timer.

## B. File ownership

Integration lead:

- `models.jac`
- `engine.jac`
- `api.jac`
- `constants.jac` (named here; not present in the tree)
- `docs/CONTRACT.md`
- tests for the engine and checkpoints (`tests/test_engine.jac`, `tests/test_checkpoint.jac`)

Frontend:

- `components/`
- `styles.css`

Reliability:

- `tools.jac`
- `recovery.jac`
- `ai.jac`
- `data/sources.json`

Shared:

- `main.jac` stays the generated entry. Nobody rewrites it to invent a second entry point.
- Nobody changes the JSON field names in this contract without the integration lead.

`tests/test_recovery.jac` is the reliability test file. It is not an integration-lead file.

## C. State machine

Statuses:

- `PENDING`
- `RUNNING`
- `COMPLETED`
- `FAILED`
- `RECOVERING`
- `NEEDS_HUMAN`
- `STOPPED`
- `PAUSED`

Legal transitions:

- `PENDING` to `RUNNING` to `COMPLETED`
- `RUNNING` to `FAILED` to `RECOVERING` to `RUNNING`
- `RECOVERING` to `NEEDS_HUMAN` or `STOPPED`
- `RUNNING` to `PAUSED` to `RUNNING`

`COMPLETED` and `STOPPED` are terminal. Reject advance, pause, and resume on a terminal run.

## D. Five steps

Each step is checkpointed only after validation.

| Index | Name | Work | Artifact |
| --- | --- | --- | --- |
| 0 | PLAN | Normalize the prompt and name the report sections. | Structured plan |
| 1 | RETRIEVE | Primary or backup curated sources. | Verified source list |
| 2 | ANALYZE | Findings that cite source ids from that list. | Findings |
| 3 | GENERATE | Structured draft from those findings. | Draft |
| 4 | VERIFY | Sections, citations, and completeness pass. | Approved report |

Example prompt, verbatim:

```text
Prepare a concise research brief about the reliability of autonomous AI agents, common failures, mitigation strategies, and recommendations.
```

## E. Node and edge schema

Graph chain:

`Root` to `TaskRun` to `TaskStep` to `FailureEvent` to `RecoveryAttempt`.

`TaskRun` to `Checkpoint`.

`TaskRun` fields: `run_id`, `prompt`, `status`, `scenario`, `current_step`, `final_output`, `created_at`.

`TaskStep` fields: `step_id`, `index`, `name`, `status`, `attempt_count`, `output`.

`FailureEvent` fields: `failure_id`, `error_code`, `category`, `message`, `step_index`, `resolved`, `simulated`.

`RecoveryAttempt` fields: `recovery_id`, `strategy`, `explanation`, `status`, `attempt_number`.

`Checkpoint` fields: `checkpoint_id`, `completed_step`, `snapshot_json`, `created_at`.

Ids are unique per run. Two runs never share steps, failures, counters, or checkpoints. Updating a status must not erase output.

## F. Public walkers

`start_run(prompt, scenario)` creates the run and five `PENDING` steps and returns the initial view.

`get_run(run_id)` returns the full view.

`list_runs()` returns runs on the authorized root.

`advance_run(run_id)` performs one step or one recovery transition.

`pause_run(run_id)` stores `PAUSED` only after the current checkpoint exists.

`resume_run(run_id)` sets `RUNNING` and does not execute a step.

`get_run_graph(run_id)` returns nodes, edges, statuses, and event ids.

`get_metrics()` aggregates stored runs. It must not contain a hardcoded success rate.

`reset_demo()` deletes demo runs only.

Every walker returns this shape. When `success` is false, `data` is null and `error` is set.

```json
{
  "success": true,
  "run_id": "run-1",
  "status": "RUNNING",
  "data": {
    "current_step": 0,
    "steps": [],
    "failures": [],
    "recovery_attempts": [],
    "checkpoints": [],
    "final_output": null
  },
  "error": null
}
```

`data` contains `current_step`, `steps`, `failures`, `recovery_attempts`, `checkpoints`, `final_output`.

`final_output` stays null until VERIFY has passed.

## G. Failure and recovery policy

Scenarios: `NORMAL`, `PRIMARY_503`, `TEMP_TIMEOUT`, `INVALID_OUTPUT`, `INTERRUPTED`, `PERMISSION_DENIED`.

Categories and the only allowed strategy:

| Category | Strategy | Rule |
| --- | --- | --- |
| `TIMEOUT` | `RETRY` | At most two retries on that step. |
| `SERVICE_UNAVAILABLE` | `FALLBACK_TOOL` | Backup must be an approved tool, then schema validation. |
| `INVALID_OUTPUT` | `REPAIR_OUTPUT` | Repair structure only. Never invent a source or citation. |
| `INTERRUPTED` | `RESUME_CHECKPOINT` | Continue at the first step that is not `COMPLETED`. |
| `PERMISSION_DENIED` | `HUMAN_APPROVAL` | Status becomes `NEEDS_HUMAN`. Never bypass permissions. |
| `UNKNOWN_ERROR`, or an exhausted budget | `STOP_AND_REPORT` | Stop and report. |

Scenario to category:

- `NORMAL` injects no failure.
- `PRIMARY_503` is `SERVICE_UNAVAILABLE`.
- `TEMP_TIMEOUT` is `TIMEOUT`.
- `INVALID_OUTPUT` is `INVALID_OUTPUT`.
- `INTERRUPTED` is `INTERRUPTED`.
- `PERMISSION_DENIED` is `PERMISSION_DENIED`.

A recovery is successful only after the post-action validation passes.

The model may explain a failure or recommend among these strategies. It must not change budgets, choose an unlisted tool, or skip permission checks.

Sources are curated fixtures in `data/sources.json` with `source_mode` `CURATED_FIXTURE`. The UI must be able to show `SIMULATED` versus a real provider error. Never present fixtures as live web search.

## H. Checkpoint and idempotency

A step becomes `COMPLETED` only after validation.

Persist output before incrementing `current_step`.

On resume, do not execute a `COMPLETED` step again.

Persistence limit. A node is stored only when it is reachable from `root`. The installed persistence reference says persistent anchors are written when the unit of work commits: a successful served request commits at its transaction boundary, and a script follows the runtime session lifecycle. In-flight work that was not committed is lost. A crash, a raised unit, or a rolled-back transaction does not leave that work in the graph. This contract does not promise exactly-once execution across a crash. The same reference replays a walker from the start after a serialization conflict, so a tool call that can repeat needs a run-and-step attempt identity. A retry must not duplicate a completed side effect.

The mission sentence "committed on request end or process exit" is the intent of that limit. The installed guide is stricter: process exit does not commit an open request. See section K.

## I. Acceptance gates

Gate 1, already met on this machine before this contract: `jac install` succeeded and `jac run --serve main.jac` served `http://localhost:8000/`. This pass did not re-run the server.

Gate 2, this document.

Gate 3: the browser shows PHOENIX and a real health-walker result, not a hardcoded connected flag.

Gate 4: two runs survive a process restart and do not leak events to each other.

Gate 5: one `NORMAL` run reaches VERIFY; a failed tool result stops in `RECOVERING` with the step not `COMPLETED`; restart continues from the last checkpoint.

Gate 6: 503 fallback, bounded timeout retry, and schema repair all verify; permission denial becomes `NEEDS_HUMAN`.

Gate 7: feature freeze. One documented launch command. README and a three-minute demo script.

## J. Commands

Recorded against this CLI (`jac 0.37.25`). `jac --help` has `run`, `check`, `test`, and `db`. It has no `start` command.

```text
jac --version
jac check .
jac check . --lint
jac test -d tests/
jac run --serve main.jac
jac db inspect
```

`jac --version` prints `jac 0.37.25  (Linux x86_64)`.

`jac check .` type-checks the workspace. `jac check . --lint` reports lint violations only.

`jac test -d tests/` is the installed form of a directory test run (`-d` / `--directory`).

`jac run --serve main.jac` is a real serve invocation. `--serve` is in `jac run --help`. For this `web-app` project, `jac run` and `jac run main.jac` also serve, because the kind decides. `jac run --dev` and `jac run --dev main.jac` serve with hot reload. Those are installed commands. They are not substitutes for a claim that `jac start` still works.

`jac db inspect` summarizes anchors by kind and archetype.

Do not use `jac start` or `jac start --dev` on this machine. They are not working commands here.

## K. Version risks

Installed version: `jac 0.37.25  (Linux x86_64)`. `jac.toml` pins `jac-version = "==0.37.25"`.

Serve-command change. `community/breaking-changes` says `jac run` absorbs `jac start` and `jac dev` (`#8596`, marked unreleased in the bundled guide). `jac start` and `jac dev` are tombstoned and hard-error. The replacement table maps `jac start app.jac` to `jac run app.jac` or `jac run --serve app.jac`, and `jac dev` to `jac run --dev`. `jac --help` matches that: there is no `start` command. `jac run --help` has `--serve` and `--dev`.

The mission said `jac start` and `jac start --dev` were removed and that the working serve command is `jac run --serve main.jac`. Installed behavior agrees that `jac start` is gone and that `jac run --serve main.jac` is valid. It disagrees on the second old spelling: the bundled guide names `jac dev`, not `jac start --dev`. `jac-fullstack-patterns` and the generated `AGENTS.md` say to start a web app with `jac run --dev main.jac`, and they say `jac serve` is not a command. `jac create`'s next step for this kind is bare `jac run`. The installed CLI wins: document `jac run --serve main.jac` as a working serve command, and also treat `jac run` and `jac run --dev` as real. Do not document `jac start`, `jac start --dev`, `jac dev`, or `jac serve` as working commands.

Scaffold difference actually seen. Before this contract, `main.jac` and `jac.toml` were empty files. `AGENTS.md` was missing. `.gitignore` was empty. `jac create phoenix --kind web-app --skip` was run outside the repo. It wrote `jac.toml`, `frontend.jac`, `frontend.impl.jac`, `main.jac`, `endpoints.jac`, `components/MessageCard.jac`, `AGENTS.md`, and `.gitignore`. Only `main.jac` and `jac.toml` were copied into this workspace. The other generated files were not added.

The copied `main.jac` is the guestbook entry. It imports `Message`, `PostMessage`, and `ListMessages` from `endpoints`, and `app` from `.frontend`. Those modules are not in this repo. The copied `jac.toml` is a `web-app` named `phoenix`, entry point `main`, with npm dependencies `jac-client-node` `1.0.7` and `@jac-client/dev-deps` `1.0.0`, and a PyPI dev dependency `watchdog >=3.0.0`. The `[client]` table is empty. The scaffold did not create `models.jac`, `engine.jac`, `api.jac`, `tools.jac`, `recovery.jac`, `ai.jac`, `styles.css`, `data/sources.json`, or the test files. Those remain the empty Phoenix files already in the tree.

Placement suffix. This repo already contains empty `components/*.cl.jac` files. The scaffold wrote `components/MessageCard.jac` with no suffix. Bundled breaking changes for jaclang 0.35 say the `.cl.jac` suffix was retired and a leftover suffixed file fails until it is renamed to `.jac` (`jac fix placement`). That rename has not been done. This contract does not perform it.

Persistence wording. Section H follows `reference/persistence` and `jac-sv-persistence`: reachability from `root`, commit at the successful request's transaction boundary, session lifecycle for a script, rollback of uncommitted work. The mission's "process exit" phrase is not a second commit point for an open served request.

No other Jac API is specified here. Walkers, nodes, and tools in sections C through H are Phoenix names for later implementation. They are not claims that the generated guestbook already provides them.
