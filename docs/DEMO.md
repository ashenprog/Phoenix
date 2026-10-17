# PHOENIX demo runbook

This runbook follows the shared contract and the hackathon guide's required vertical slice: one controlled, simulated primary 503, backend-selected fallback, verified recovery, and a final report. The browser displays backend responses; it does not manufacture outcomes.

## Start the app

From the project root, `/Users/ashen/Projects/Phoenix/Phoenix`, run:

```sh
jac --version
jac install
jac check components/Dashboard.jac components/ChaosLab.jac components/Metrics.jac components/ExecutionGraph.jac components/RecoveryTimeline.jac
jac start --dev
```

Keep that terminal and server running for all rehearsals. Open the exact local app URL:

- Dashboard: `http://localhost:8000/`
- Jac API base: `http://localhost:8001/`
- Health check function: `POST http://localhost:8001/function/phoenix_health`
- Demo walker endpoints:
  - `POST http://localhost:8001/function/start_run`
  - `POST http://localhost:8001/function/get_run`
  - `POST http://localhost:8001/function/advance_run`
  - `POST http://localhost:8001/function/pause_run`
  - `POST http://localhost:8001/function/resume_run`
  - `POST http://localhost:8001/function/get_run_graph`
  - `POST http://localhost:8001/function/get_metrics`

The demo uses deterministic fixtures; it needs no model API key. The Jac CLI prints the authoritative local and network URLs if the port differs.

## Primary demo: simulated API 503 and verified fallback

Run each rehearsal as a new run; do not restart the server between attempts.

1. Open `http://localhost:8000/`.
2. In **What should PHOENIX research?**, enter `Research dependable AI agent reliability practices`.
3. In **Chaos Lab · choose a scenario**, click **API 503**. Confirm it has the selected styling and `aria-pressed` state.
4. Click **Start run** once. Wait for the backend response. The run card should show a new `run-…` ID, `PENDING`, and `0 of 5 steps completed`.
5. Click **Advance one step** and wait for each response before clicking again. Continue until the status badge says **COMPLETED** and the report appears. In rehearsals on 2026-10-17, this took six advances. If one response takes longer, wait; do not double-click.
6. Point out these actual backend results:
   - Status **COMPLETED**, all five workflow steps **COMPLETED**, and no more Advance button.
   - Graph nodes show a red **SERVICE_UNAVAILABLE / FAILED** node and green completed steps. The fallback node is **FALLBACK_TOOL / VERIFIED**; graph connections come from `get_run_graph`.
   - Event timeline records the simulated failure and recovery events; the failure is labelled **SIMULATED**.
   - The report card shows its backend title, summary, findings, recommendations, and returned source IDs (the 2026-10-17 fixture run returned `fixture-backup-1`).
   - Metrics refresh from `get_metrics`. Average latency is currently `Not measured` because the API returns `null`.
7. If desired, click **Refresh from server** at completion. The run remains completed; refresh does not advance it.

The sequence is backend-driven. Treat the labels above as expected evidence, not a substitute for checking the actual response. If the run fails to recover or the response differs, report what the server returned rather than presenting the demo as successful.

## Pause and resume (optional)

1. Start a fresh run using **Normal**.
2. Click **Pause**. Expect the backend status **PAUSED**, a **Run paused** event, and a **Resume** button instead of Advance.
3. Click **Resume**. Expect the backend status to return to **RUNNING**, a **Run resumed** event, then **Pause** and **Advance one step** controls.

These controls call `pause_run` and `resume_run`. They do not simulate a state change locally.

## Safe-stop scenario (optional)

1. Enter a task, click **Permission Denied**, then click **Start run**.
2. Click **Advance one step** until the backend returns **NEEDS_HUMAN**.
3. Confirm the graph indicates the purple human-action recovery and the UI no longer offers Advance. Do not imply that PHOENIX bypasses the permission requirement.

## Clean reruns and fallback plan

There is no `reset_demo` walker in the current public API, so there is no Reset Demo button and no destructive reset step. Each **Start run** creates an independent run with fresh per-run scenario state. For a clean rehearsal, start a new run and use its new ID; leave the server and prior history alone.

If the live API 503 rehearsal cannot finish:

1. Do not change the selected node colors or claim an unreturned recovery.
2. Click **Refresh from server** and inspect the run state, event timeline, graph, and diagnostics.
3. If this run is stuck, keep it as evidence and start another fresh **API 503** run. Do not restart the server between rehearsal attempts.
4. If the server is unavailable, leave the UI error visible and show the already captured, explicitly labelled simulated-fault screenshot only as a backup. State that it is a screenshot of a controlled simulation, not a live production outage.

## Three-rehearsal log

All attempts below use the same running Jac dev server; each began by starting a fresh run from the blank new-task form. “Six advances” means six sequential clicks, waiting for the response each time.

| Rehearsal | Run ID | Scenario | Result |
|---|---|---|---|
| 1 | `run-41fac86f-9309-4161-836a-e8709aeecdbe` | `PRIMARY_503` | Completed after six advances; observed `RUNNING → RECOVERING → RUNNING → RUNNING → RUNNING → COMPLETED`; five steps completed; verified `FALLBACK_TOOL`; returned source ID `fixture-backup-1`. |
| 2 | `run-1460f1f4-c685-4abb-97c3-55abdbbfcea2` | `PRIMARY_503` | Completed after six advances; observed `RUNNING → RECOVERING → RUNNING → RUNNING → RUNNING → COMPLETED`; five steps completed; verified `FALLBACK_TOOL`; returned source ID `fixture-backup-1`. |
| 3 | `run-c93fc6ea-e585-452a-8751-ca851c2935bf` | `PRIMARY_503` | Completed after six advances; observed `RUNNING → RECOVERING → RUNNING → RUNNING → RUNNING → COMPLETED`; five steps completed; verified `FALLBACK_TOOL`; returned source ID `fixture-backup-1`. |

All three runs were started and advanced on the same Jac dev-server process, without a server restart. Each live response included the `SERVICE_UNAVAILABLE` failure node and a verified `FALLBACK_TOOL` node. `fixture-backup-1` was the source ID displayed in the returned final report for each.

## Three-minute spoken script

> **0:00–0:30 — Introduce PHOENIX.** “PHOENIX runs research through a five-step workflow: Plan, Retrieve, Analyze, Generate, and Verify. The backend owns state and recovery decisions; the dashboard is a monitor and controller. We use deterministic trusted fixtures, so this demo does not require an external model or live research API.”
>
> **0:30–1:00 — Start the controlled scenario.** “I’ll enter a research task and choose API 503 in the Chaos Lab. This is an explicitly simulated fault, not a real service outage. When I click Start run, the selected scenario is sent to the backend with the task. The run ID and initial status come back from `start_run`.”
>
> **1:00–2:00 — Show the failure and recovery.** “I’ll advance one backend transition at a time. Watch the real status and completed-step count. The primary retrieve path records a service-unavailable failure. PHOENIX selects its approved fallback; the graph highlights the failure in red and reports the recovery status from the server. The event timeline is an audit trail, and its SIMULATED tag makes the controlled fault clear. The browser never invents a failed node or claims recovery before verification.”
>
> **2:00–2:35 — Verify the result.** “The run now reports COMPLETED and all five steps are complete. The final report card shows the returned title, executive summary, findings, recommendations, and fixture source IDs. Metrics are fetched from recorded runs. If latency is not supplied, we say Not measured rather than estimating.”
>
> **2:35–3:00 — Explain safe boundaries.** “A permission-denied scenario stops at NEEDS_HUMAN; PHOENIX does not bypass policy. Pause and Resume, when used, call the backend operations. There is no Reset Demo operation, so each rehearsal starts a new independent run instead of clearing history. This is a controlled, fixture-backed reliability demo, not a claim of production outage performance.”

## Developer 1 integration note

`main.jac` currently imports and mounts `Dashboard` and imports `styles.css`. The component exports are:

| Export | Required props |
|---|---|
| `Dashboard` | none |
| `ChaosLab` | `scenario: str`, `onScenarioChange: Callable[[str], None]` |
| `ExecutionGraph` | `nodes`, `edges`, `steps`, `events`, `recoveries` (`list[dict[str, any]]`); `run_id`, `run_status`, `error` (`str`); `loading`, `has_run` (`bool`) |
| `Metrics` | `metrics: dict[str, any] \| None`, `error: str`, `loading: bool`, `onRefresh: Callable[[], None]` |
| `RecoveryTimeline` | `events`, `recoveries` (`list[dict[str, any]]`); `has_run: bool` |

`Dashboard` calls these public API walkers: `start_run(prompt, scenario)`, `get_run(run_id)`, `advance_run(run_id)`, `get_run_graph(run_id)`, `get_metrics()`, `pause_run(run_id)`, and `resume_run(run_id)`. All return data used by the dashboard; state, graph edges, recovery decisions, and final report remain backend-owned. `reset_demo` is documented in the contract but is not currently exported by `api.jac`.

Keep the global `styles.css` import in the app entry so the exported components retain their dark theme, readable status colors, responsive layout, and focus indicators. The browser-facing Jac component code must follow the installed `jac guide jac-cl-components` syntax.

## Screenshot and provenance

[Execution graph screenshot](./screenshots/phoenix-primary-503-simulation.png) and [final report screenshot](./screenshots/phoenix-primary-503-report.png) are **controlled simulated-fault** screenshots captured at a 1366×768 browser viewport after a completed `PRIMARY_503` smoke run (`run-cac2fa8d-884d-4bf0-9cdf-786ca3af8612`). The graph shows a red `SERVICE_UNAVAILABLE` node and verified `FALLBACK_TOOL`; the report screenshot shows its returned fixture source ID. Do not label these as a real external outage. Use this caption in README or backup slides: `PHOENIX controlled PRIMARY_503 simulation — fixture recovery`.
