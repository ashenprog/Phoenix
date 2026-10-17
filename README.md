# Phoenix

PHOENIX is a Jac-based reliability layer that executes a multi-step AI research workflow, detects tool and output failures, selects approved recovery strategies, preserves checkpoints, and transparently shows the recovery path in a live graph.

Shared API shapes and statuses: [docs/CONTRACT.md](docs/CONTRACT.md).

## Prerequisites

- [Jac CLI](https://www.jac-lang.org/quick-guide/install/) (`jac --version`)
- Git
- **Windows:** run Jac from **WSL2 Ubuntu** (the Linux installer). PowerShell alone does not include the `jac` binary unless you install it separately.

Install Jac (Linux / macOS / WSL):

```sh
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
```

Restart the terminal, then:

```sh
jac --version
git --version
```

No AI API key is required for the initial deterministic demo.

## Setup and run

From the project root (this folder):

```sh
jac install
jac check .
jac run --dev
```

Open the URL printed in the terminal (typically `http://localhost:8000/`). You should see the PHOENIX dashboard with global styles applied.

Health check (backend API on port 8001):

```sh
curl -s -X POST http://localhost:8001/function/phoenix_health -H 'Content-Type: application/json' -d '{}'
```

Expected JSON includes `"service": "phoenix"`. App UI: `http://localhost:8000/`.

## Suggested branch (Developer 1)

```sh
git switch -c dev1-core
```

## Verify

```sh
jac check .
jac test -d tests/
```

In the browser (`jac run --dev`), start a **NORMAL** run and use **Advance** until the report appears; repeat with **PRIMARY_503** to see a simulated failure and verified fallback.

## Known limits

- Faults are **controlled fixture scenarios** (`data/sources.json`), not live external outages.
- Report wording uses **`DETERMINISTIC_FALLBACK`** (no LLM API key required).
- Metrics `baseline_vs_phoenix` counts come from the five-scenario fixture benchmark in `recovery.jac`, not production reliability data.

Commit only files you own; see file ownership in [docs/CONTRACT.md](docs/CONTRACT.md).
