---
name: kaggle-operator
description: Operate Kaggle Cloud environments via the `kaggle` CLI: verify/publish model & dataset dependencies, push GPU notebooks, monitor batch execution, retrieve logs, and run an autonomous fix-and-verify loop until LLM inference servers are healthy.
---

# Skill: Kaggle Cloud Session & Deployment Operator

Execute Kaggle Cloud operations via pre-built scripts in `scripts/`.

## Pre-Built Operations (`scripts/`)

| Operation | Invocation | Purpose |
|:---|:---|:---|
| `deploy_kaggle` | `python3 scripts/deploy_kaggle.py <kaggle_dir> [--model-work-dir <dir>]` | Verifies `dataset_sources` / `model_sources` on Kaggle Cloud, runs `publish_kaggle_dataset.sh create` / `publish_kaggle_model.sh` if missing, then runs `kaggle kernels push`. |
| `check_kaggle_run` | `bash scripts/check_kaggle_run.sh <kaggle_dir> [output_dir]` | Checks `kaggle kernels status` and downloads logs via `kaggle kernels output` on `ERROR` or `COMPLETE`. |

## Execution Constraints
- **Batch Mode (`papermill`)**: `kaggle kernels push` runs asynchronously (no persistent REPL); notebooks must use log snapshots instead of `while True:` to reach `KernelWorkerStatus.COMPLETE`.
- **Lightweight `/kaggle/working`**: Keep `.venv` and 20GB+ models in `/tmp/` so `kaggle kernels output` downloads only logs.

## Execution Pipeline
1. `deploy_kaggle(<kaggle_dir>)` — ensures all Dataset/Model dependencies exist on Kaggle Cloud, then pushes the notebook.
2. `check_kaggle_run(<kaggle_dir>, <out_dir>)` — polls until `COMPLETE` or `ERROR`.
3. **On `ERROR`**: inspect `<out_dir>/<slug>.log` and `logs/*.log`, patch locally, and re-run `deploy_kaggle(<kaggle_dir>)`.
4. **On `COMPLETE`**: verify all endpoints in `http.rest` (`/healthz`, `/api/v1/status`, `/v1/models`, `/v1/chat/completions`, etc.) before reporting success.

## Trigger & Exit Criteria
- **Trigger**: Deploying or debugging a Kaggle notebook, model, or dataset via `kaggle` CLI.
- **Exit Criteria**: Dependencies exist on Kaggle Cloud, `check_kaggle_run` reaches `KernelWorkerStatus.COMPLETE`, and all `http.rest` endpoints pass.

## Anti-Patterns
- Never run `kaggle kernels push` before verifying/creating `dataset_sources` and `model_sources`.
- Never ignore `409 Conflict` slug/title mismatches or store large model downloads in a small tmpfs `/tmp` (use `/mnt/d/tmp`).
