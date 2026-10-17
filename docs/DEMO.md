# PHOENIX dashboard demo

This guide runs the dashboard against the Jac backend. The browser displays responses from the API; it does not make up run status, graph nodes, recovery events, or metrics.

## 1. Install and start

Open a terminal in the project root and run:

```sh
jac --version
jac install
jac check .
jac start --dev
```

Keep the server running. Open the local URL printed by Jac (usually `http://localhost:8000/`). The deterministic demo does not require an AI API key. Run `jac install` again only if the project dependencies change or the install reports missing packages.

## 2. Run a normal task

1. Enter a short research task, for example: `Research how teams improve AI agent reliability`.
2. Select **Normal run**.
3. Select **Start run**. The dashboard submits the task to `start_run`.
4. Use **Advance one step** to request one backend transition at a time. Use **Refresh from server** to reload without advancing.
5. Check the backend-returned status, completed-step count, graph nodes and connections, chronological events, and final report. After a terminal status (`COMPLETED`, `STOPPED`, `PAUSED`, or `NEEDS_HUMAN`), the Advance button is removed.

Metrics are loaded from `get_metrics` and refreshed after run actions. The current backend reports average latency as `null`; the dashboard displays **Not measured** rather than inventing a value. The current baseline comparison is the value supplied by the API, not an independently measured benchmark.

## 3. Show recovery and safe-stop behavior

- **Simulated API 503:** select **Simulated API 503**, start a task, then advance through the returned transitions. The backend should record the primary service failure and, if fallback succeeds, a verified recovery and resumed run. Inspect the actual timeline and graph connections.
- **Simulated permission denied:** select **Simulated permission denied**, start a task, and advance until the backend reports `NEEDS_HUMAN`. The dashboard should stop offering Advance; it does not bypass the policy stop.
- **Other scenarios:** `TEMP_TIMEOUT` and `INVALID_OUTPUT` can be selected to demonstrate the backend's retry and output-repair paths.

Recovery outcomes depend on the backend response. Do not infer success from the selected scenario alone; check the returned run status and recovery attempt status.

## 4. Read the display

- **Progress** counts only steps marked `COMPLETED` in the latest run response. Refresh fetches state; Advance requests one backend transition.
- **Workflow graph** renders nodes and edges returned by `get_run_graph`. An unavailable graph is shown as an error, not replaced with locally generated edges.
- **Event timeline** retains the order returned by the backend. The UI can label `TOOL_EXECUTED` if the API provides it, but the current backend does not emit that event type, so no tool-execution entries appear in this demo.
- **Recovery resume events** are also shown only when returned. In the current successful 503 fallback test, the backend completes the run without emitting `RUN_RESUMED`; the UI does not synthesize that event based on the later step transitions.
- **Run metrics** show recorded backend counts. A server or invalid-run error is shown in the relevant panel; use its refresh action to retry.
- **Status styling:** `NEEDS_HUMAN` is purple, `COMPLETED` is green, and failure/stopped states are red.

## 5. If something goes wrong

1. Leave the Jac server running and confirm the browser is using the URL it printed.
2. For a connection error, check the terminal for server errors, then select **Retry display / Refresh** or **Refresh metrics**.
3. An invalid or unavailable run ID cannot be repaired by the browser. Start a new run.
4. If a request is already running, wait for it to finish before trying another action. The dashboard prevents overlapping requests.
5. Check Jac diagnostics from the project root:

   ```sh
   jac check components/Dashboard.jac
   jac test -d tests/
   ```

## Short demo talk track

> PHOENIX runs a research task through the backend's controlled workflow. I can advance one backend transition at a time or refresh the returned state. The graph and timeline show only what the backend recorded. Here the simulated 503 path shows the failure and recovery, and the permission-denied path stops for human action rather than bypassing policy. Metrics also come from recorded runs; latency is marked unavailable until the backend measures it.