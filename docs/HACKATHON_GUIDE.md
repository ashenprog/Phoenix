# PHOENIX Hackathon Guide

This is a concise, original summary of the PHOENIX three-developer, eight-hour build plan. It is meant to help the team build and present one working demo; it is not a word-for-word copy of the source handbook.

## 1. The goal

Build a small Jac application that runs a five-step research task. In the main demo, the primary research tool encounters a controlled, simulated 503 error. PHOENIX records the failure, selects an approved backup tool, verifies its result, resumes from saved progress, and produces a verified report. The dashboard makes the failure and recovery visible.

Prioritize a complete, honest vertical slice over extra features. Live external research APIs and an AI model are optional; a deterministic offline demo is enough.

## 2. Team roles and file ownership

Keep the existing project structure. Read and coordinate before changing files owned by another developer.

| Role | Main responsibility | Primary files |
|---|---|---|
| Developer 1: Core and integration | Jac project setup, shared contract, data model, execution engine, public API, checkpoints, integration | `main.jac`, `jac.toml`, `models.jac`, `engine.jac`, `api.jac`, `tests/test_engine.jac`, `tests/test_checkpoint.jac`, `docs/CONTRACT.md`, `README.md`, `.gitignore` |
| Developer 2: Frontend and demo | Dashboard, graph, timeline, scenario controls, metrics, styling, demo instructions | `components/*.cl.jac`, `styles.css`, `docs/DEMO.md` |
| Developer 3: Tools and recovery | Fixture sources, tool functions, fault injection, safe recovery policy, recovery tests, optional AI report help, benchmark evidence | `tools.jac`, `recovery.jac`, `ai.jac`, `data/sources.json`, `tests/test_recovery.jac` |

Developer 1 owns integration. Developer 2 and Developer 3 should share their component or recovery interfaces with Developer 1 rather than editing the core engine or project configuration independently.

## 3. Setup

### Requirements

- Jac CLI (the VS Code Jac extension alone is not the CLI)
- Git and access to the team's shared repository
- VS Code or another editor and a coding assistant with terminal access
- One reliable computer to run the app and one browser
- An AI model key is optional; do not block the initial demo on one

### Install and start

Run these commands from the existing project folder. Do not create a second project inside it.

```sh
jac --version
git --version
jac guide
```

If Jac is missing on macOS, Linux, or WSL Ubuntu, the official installer is:

```sh
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
```

Restart the terminal if necessary, then check `jac --version` again. For a first-time Windows setup, WSL2 with Ubuntu is an option; prepare it before the hackathon because setup may require a restart.

Only after `jac.toml` contains valid project configuration, install dependencies and verify/start the app:

```sh
jac install
jac check main.jac
jac start --dev
```

Open the local URL printed by Jac (often port 8000). Jac is distributed as a self-contained executable in current guidance; a separate Python runtime is not assumed. Do not run `jac create` inside the existing project. If its configuration is only a placeholder, create a temporary official web-app scaffold elsewhere and copy over only the necessary, verified setup.

Optional AI reporting comes later. If it is needed, Developer 3 should coordinate with Developer 1 before adding the optional `byllm` dependency. Keep deterministic mode working without an API key.

## 4. Shared application contract

Developer 1 drafts `docs/CONTRACT.md`; all developers agree on it by minute 45. Treat its field names and response shapes as the source of truth.

Suggested statuses:

- Run: `PENDING`, `RUNNING`, `RECOVERING`, `PAUSED`, `NEEDS_HUMAN`, `COMPLETED`, `STOPPED`
- Step: `PENDING`, `RUNNING`, `FAILED`, `COMPLETED`
- Recovery: `PROPOSED`, `RUNNING`, `VERIFIED`, `FAILED`, `EXHAUSTED`

The UI is a monitor and controller, not the authority on run state. The backend must originate status changes, failure events, recovery decisions, and checkpoints. Never invent progress in the browser.

Suggested public operations (confirm the final interface and payloads in the contract):

| Operation | Purpose |
|---|---|
| `start_run` | Start a prompt with a selected scenario; return a run ID and initial state |
| `get_run` | Return a run's current state, steps, and timeline |
| `advance_run` | Perform one workflow transition |
| `pause_run` / `resume_run` | Pause and resume from the saved checkpoint, if implemented |
| `get_run_graph` | Return graph nodes and edges for display |
| `get_metrics` | Return measurements calculated from recorded runs |
| `reset_demo` | Clear only explicitly scoped demo fixtures, never all user data |

A run response should carry enough information for the UI to display the run ID, prompt, scenario, status, current step, steps, events, recovery attempts, checkpoint, final report, and model mode. Keep the returned shape consistent with the agreed contract.

## 5. Workflow and recovery behavior

The intended workflow has five ordered steps:

1. **Plan** — turn the request into a short outline.
2. **Retrieve** — fetch trusted fixture research sources.
3. **Analyze** — validate source records and summarize findings.
4. **Generate** — create the report.
5. **Verify** — check required sections and source references.

Controlled scenarios:

- `NORMAL` — no injected failure
- `PRIMARY_503` — primary source fails; approved backup can be used
- `TEMP_TIMEOUT` — a transient timeout occurs once, then retry can succeed
- `INVALID_OUTPUT` — one invalid response is rejected and repaired or re-run
- `PERMISSION_DENIED` — stop safely and request human action; never bypass permission

Classify failures and select recovery deterministically. Typical choices are backup tool for service unavailability, bounded retry for a timeout, validation/repair for invalid output, checkpoint resume after interruption, human approval for permission denial, and stop for unknown errors. Enforce limits (the plan suggests at most two retries per step and three recovery attempts per run); no infinite retry loops or arbitrary commands.

A recovery counts as successful only when its action actually ran and its output passed verification. A final success requires a verified report whose source IDs exist in the trusted fixture set. Resuming must preserve completed work and continue at the first incomplete step. Clearly label injected faults as simulated.

## 6. Eight-hour schedule and team gates

| Time | Focus |
|---|---|
| 00:00–00:30 | Verify Jac and Git, start the existing project, draft the contract; sketch the UI and plan fixtures |
| 00:30–01:15 | Create run model and dashboard layout; prepare sample source tools |
| 01:15–02:00 | Implement one-step execution, run controls, failure injection, and classification |
| 02:00–03:00 | Add public operations and persistence; build graph/timeline and bounded retry/fallback/repair |
| 03:00–04:00 | Integrate the first recovery path, wire Chaos Lab to the backend, and test |
| 04:00–05:00 | Verify checkpoint/resume; improve UI; add AI only if the core flow is stable |
| 05:00–06:00 | Smoke test and merge tested work; polish the demo; test benchmark logic |
| 06:00–07:00 | Fix critical issues, rehearse, document setup and known limits |
| 07:00–08:00 | Feature freeze; test, rehearse, and submit |

**Gates**

- Minute 45: everyone agrees on the contract.
- Hour 2: a normal task runs and a fault can be injected.
- Hour 4: the browser shows a real backend failure, approved recovery, and continuing task.
- Hour 7: stop adding features; focus only on fixes, tests, demo, and submission.

At Hour 4, if the full demo is not working, stop adding features and make `PRIMARY_503 -> FALLBACK_TOOL -> verified report` reliable first.

## 7. Developer 2: frontend checklist

1. Read the contract and the current Jac client guides (`jac guide`) before choosing syntax.
2. Build the dashboard with task input, scenario selection, Start, progress, graph, timeline, and results.
3. Connect task start and refresh to the agreed backend operations. Prevent overlapping requests and stop refreshing when a run is terminal or waiting for a person.
4. Display graph nodes and edges from backend data. Make each node reveal its real status and useful output/error/recovery details. Use a simple linear diagram if an interactive graph is unreliable.
5. Add visible scenario controls for normal, 503, timeout, invalid output, and permission denied. Controls must request backend scenarios; they must not fake failures by changing colors.
6. Show real metrics only. If there are no recorded runs, say so instead of showing sample percentages.
7. Show the verified report and actual fixture source IDs. Only show Pause, Resume, or Reset when the corresponding backend operation exists.
8. Make text and diagrams readable on a projector. Document exact demo clicks, expected states, a fallback, and a short speaking script in `docs/DEMO.md`.

Suggested status colors: pending gray, running blue, completed green, failed red, recovering orange, and needs-human purple. Use a high-contrast layout and keep the screen legible around 1366×768.

## 8. Developer 3: recovery and optional AI checklist

1. Create a small, clearly labeled fixture dataset; don't present fabricated links or claims as authoritative research.
2. Make tool responses follow one agreed shape, such as `ok`, `data`, `error_code`, `error_message`, `tool_name`, and `source_mode`.
3. Make each injected fault deterministic and scoped to its own run—not a global counter.
4. Test ordinary success, fallback after 503, retry after timeout, invalid-output repair, permission stop, and exhausted retry limits. Interleave runs to check their state does not leak.
5. Add optional model-based report wording only after deterministic recovery works. The model may not authorize tools or change retry limits. Validate its output and use a labeled deterministic fallback if the key is missing or the response is invalid.
6. Calculate benchmark numbers from actual recorded runs. State limitations; a small fixture demo does not prove production reliability.

## 9. Testing, collaboration, and integration

After each focused change, run the smallest relevant `jac check` and test. Before submission, aim to run:

```sh
jac check .
jac test -d tests/
jac start --dev
```

Verify the actual browser flow and record failures honestly. Test pause/restart behavior: completed steps should remain completed after resume, and repeated advance calls should not duplicate finished work. Be aware that an operation in flight at process crash may need to be retried; avoid duplicate external side effects.

Use separate branches when working in separate clones, inspect `git status` first, and commit only files in your ownership. Share the branch/commit and any API changes. Developer 1 merges one tested branch at a time, checks imports, and runs tests. Do not initialize a second Git history or force-push shared history. Never commit API keys, and configure ignore rules for actual secrets and generated files.

When an error occurs, give the coding assistant one narrow task, the exact error, the relevant contract, and the files it may change. Ask it to use `jac guide` when Jac syntax is unclear, inspect the diff, and show real command/test/browser results. If blocked for more than about ten minutes, reduce scope to the smallest working flow.

## 10. Three-minute demo

Prepare and test both a `NORMAL` run and a `PRIMARY_503` run before presenting.

| Time | Show |
|---|---|
| 0:00–0:25 | Empty dashboard; explain that multi-step agents can fail mid-task |
| 0:25–0:55 | Enter a task, select `PRIMARY_503`, and start |
| 0:55–1:25 | Show completed planning and the visibly failed retrieval step; explain the fault is simulated |
| 1:25–1:55 | Show the approved backup executing and its result being verified |
| 1:55–2:20 | Show the task continuing and the verified report; point out preserved progress |
| 2:20–2:40 | Open the timeline/incident details to show what failed and what recovered |
| 2:40–3:00 | Show real benchmark data or the checkpoint/resume behavior |

Before the demo, disable unrelated notifications, keep the server and browser ready, check the local URL, and have a known-good commit. If external connectivity fails, use seeded fixtures and label the demo offline. Say whether report wording used a live model or deterministic fallback.

## 11. If something goes wrong

- Jac will not start on one laptop: use the designated host; continue coding in supported environments.
- Client syntax is taking too long: use a minimal valid Jac client component and a simple status list.
- A graph library is incompatible: draw the five steps with basic Jac UI, SVG, or CSS; avoid new dependencies.
- No model key or model outage: keep deterministic fallback.
- Persistence is not ready: demonstrate saved per-request progress and be clear about the limitation; do not claim restart recovery works.
- Branch integration breaks imports: revert or omit the smallest failing integration change; keep the last known-good app.
- Metrics are not ready: show truthful per-run events and drop the comparison chart.
- Only 15 minutes remain: run the demo twice, record the start command, and stop coding.

Feature priority:

- **Must ship:** Jac server, browser task creation, five-step progression, one simulated failure, one automatic verified recovery, completed report.
- **Add if stable:** graph, timeline, checkpoints, pause/resume, more fault scenarios.
- **Optional:** model-generated explanation, benchmark dashboard, human approval UI.
- **Skip:** accounts, payments, Kubernetes, live web crawling, and complex multi-agent orchestration.

## 12. Final acceptance checklist

- [ ] Jac CLI and documented server command work.
- [ ] Existing project layout is preserved and modules load.
- [ ] A browser user can start a task and see all five steps progress.
- [ ] `PRIMARY_503` creates a real backend failure event.
- [ ] An approved fallback executes and passes verification.
- [ ] Resume does not redo completed steps.
- [ ] The final report cites only permitted fixture sources and passes verification.
- [ ] The UI shows backend graph state and chronological recovery events.
- [ ] Permission denial stops safely.
- [ ] Contract, tests, README setup, demo instructions, and known limitations are accurate.
- [ ] Changes are integrated and checked; no API keys or unnecessary generated files are committed.
- [ ] The clean demo has been rehearsed at least twice.

Do not claim production-grade autonomous reliability, real external outages from simulated faults, or measured success rates without data. Present observable behavior and evidence.

## Official Jac references

Jac changes over time; check the installed version's `jac guide` and the current official docs:

- [Install Jac](https://www.jac-lang.org/quick-guide/install/)
- [Jac CLI](https://www.jac-lang.org/reference/cli/)
- [Full-stack setup](https://www.jac-lang.org/tutorials/fullstack/setup/)
- [Agent Skills and MCP](https://www.jac-lang.org/reference/agent-skills-and-mcp/)
- [Jac MCP quick start](https://www.jac-lang.org/tutorials/ai/mcp-quickstart/)
- [Jac language reference](https://www.jac-lang.org/reference/)

Useful commands: `jac install` installs project dependencies, `jac check` checks source, `jac test` runs tests, and `jac start --dev` starts the development server.
