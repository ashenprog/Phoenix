# Phoenix

PHOENIX is a Jac full-stack demo that runs a five-step AI research workflow, injects **controlled simulated faults**, selects **bounded recovery strategies**, preserves **checkpoints**, and shows failures and recovery on a live dashboard. The backend owns all run state; the browser only monitors and controls runs through the public API.

Shared API shapes: [docs/CONTRACT.md](docs/CONTRACT.md).

## What it does

1. **Plan** — outline from your prompt  
2. **Retrieve** — fixture research sources (`data/sources.json`)  
3. **Analyze** — validate sources  
4. **Generate** — build a report  
5. **Verify** — check report schema and allowed source IDs  

When a step fails, PHOENIX classifies the failure, picks a strategy (fallback tool, retry, repair output, human approval, or stop), verifies recovery output, and continues without redoing completed steps. Checkpoints record the last completed step index.

## Prerequisites

- [Jac CLI](https://www.jac-lang.org/quick-guide/install/) (`jac --version`)
- Git  
- **Windows:** use **WSL2 Ubuntu** for the Jac CLI unless you installed `jac` separately on Windows.

Install Jac (Linux / macOS / WSL):

```sh
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
```

No AI API key is required; reports use **`DETERMINISTIC_FALLBACK`** wording.

## How to run

From this folder (`Phoenix/`):

```sh
jac install
jac check .
jac run --dev
```

Open the URL from the terminal (usually `http://localhost:8000/`).

Health check (API, typically port 8001):

```sh
curl -s -X POST http://localhost:8001/function/phoenix_health -H "Content-Type: application/json" -d "{}"
```

Expected JSON includes `"service": "phoenix"`.

Run tests:

```sh
jac check .
jac test -d tests/
```

## What you can do in the dashboard

### Start a normal run

1. Enter a research prompt.  
2. In **Chaos Lab**, choose **Normal**.  
3. Click **Start run**, then **Advance one step** until the verified report appears.

### Simulated fault scenarios (Chaos Lab)

| Scenario | What happens |
|----------|----------------|
| **Normal** | No injected fault |
| **API 503** | Primary retrieve fails; **FALLBACK_TOOL** to backup sources |
| **Timeout** | One transient timeout, then **RETRY** |
| **Invalid output** | Bad schema once, then **REPAIR_OUTPUT** (see repair diff in timeline) |
| **Permission denied** | Run stops at **NEEDS HUMAN**; use **Approve** or **Deny** |

All faults are **simulated** and scoped per run.

### Play 503 recovery (presenter-friendly)

- **Play 503 recovery** starts a 503 scenario and advances until the **first failure**, then **pauses** so you can explain the failed Retrieve step.  
- Click **Continue demo** to finish through verified fallback and the report.

### Human approve / deny

When status is **NEEDS HUMAN** (permission denied):

- **Approve** — grants a one-time human override and runs the approved **backup** retrieve, then continues the workflow.  
- **Deny** — stops the run safely (`STOPPED`).

### Pause, checkpoint, resume

- **Pause** while **RUNNING** or **RECOVERING**; the **checkpoint viewer** shows which completed steps are preserved.  
- **Resume** continues at the first incomplete step without re-running finished steps.

### Run history and reset demo

- **Run history** lists session runs from the backend; click a row to load that run.  
- **Reset demo** clears session runs only (not fixture sources).  
- **Refresh list** reloads history.

### Workflow graph (incident view)

The **Workflow graph** shows all steps plus **every** failure and recovery node returned by `get_run_graph`. Select a node to inspect step output/errors, failure category, or recovery strategy and reason.

### Recovery policy card

The timeline panel includes a **Recovery policy** card: failure category, selected strategy, reason, and retries/recoveries used vs limits (2 retries per step, 3 recoveries per run).

### Repair diff

For **Invalid output** runs, the timeline shows **Rejected** vs **Repaired** payloads after verification.

### Metrics and baseline vs PHOENIX

**Run metrics** come from recorded runs only. The **fixture benchmark** compares baseline (stop on fault) vs PHOENIX (bounded recovery) across five scenarios. **Average step latency** appears when steps have start/complete timestamps.

### Source drawer

In the final report, click a **source ID** to open fixture title, tier (`primary` / `backup`), and excerpt from `data/sources.json`.

### Presenter mode

Toggle **Presenter mode** in the top bar for larger type and a status strip. Press **N** to advance one step while presenter mode is on.

## Known limits

- Faults are **fixture scenarios**, not live external outages.  
- Report text is **deterministic** unless you add optional live model wiring (`ai.jac`).  
- Benchmark and baseline counts are from **`recovery.jac`** fixture runs, not production reliability data.  
- Metrics empty state: **No test runs yet** until you start at least one run.

## API operations (backend)

| Operation | Purpose |
|-----------|---------|
| `start_run` | Start prompt + scenario |
| `get_run` / `advance_run` | Read and step the workflow |
| `pause_run` / `resume_run` | Checkpoint pause/resume |
| `human_decision` | Approve or deny `NEEDS_HUMAN` runs |
| `get_run_graph` | Graph nodes and edges |
| `get_metrics` | Recorded run stats + benchmark |
| `list_runs` | Session run list |
| `reset_demo` | Clear session runs (`scope`: `session_runs`) |
| `get_fixture_sources` | Fixture catalog for source drawer |
