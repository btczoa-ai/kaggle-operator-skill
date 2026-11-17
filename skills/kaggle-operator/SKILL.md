---
name: kaggle-operator
description: Operate Kaggle Cloud environments via the `kaggle` CLI: push GPU notebooks, monitor batch kernel execution, retrieve logs, and run an autonomous self-improvement loop until LLM inference servers are verified healthy.
---

# Skill: Kaggle Cloud Session & Deployment Operator

Operate Kaggle Cloud environments via the `kaggle` CLI (`kaggle kernels push`, `kaggle kernels status`, `kaggle kernels output`) to deploy notebooks and run LLM inference backends.

## When to activate
- Deploying or updating a notebook on Kaggle Cloud (`kaggle kernels push`).
- Monitoring batch execution status (`RUNNING` / `COMPLETE` / `ERROR`).
- Retrieving execution logs and debugging remote Kaggle GPU failures.
- Running an autonomous self-improvement deployment loop for LLM inference servers.

## Mental model (Kaggle vs. Colab)
- **Batch Execution Model**: `kaggle kernels push -p <dir>` uploads the notebook + `kernel-metadata.json` and triggers an asynchronous batch run (`papermill`). Unlike Colab's interactive kernel, there is no persistent live REPL via CLI.
- **Working Directory (`/kaggle/working`)**: Everything left in `/kaggle/working` at the end of a run is archived as kernel output. **Never** place `.venv`, `llama.cpp` source trees, or 20GB+ model files in `/kaggle/working` — place them in `/tmp/` (`VENV_DIR=/tmp/.venv`, `MODELS_DIR=/tmp/models`) so `kaggle kernels output` downloads only lightweight logs in seconds.
- **No Infinite Loops in Batch Mode**: Replace `while True:` log-tailing cells with bounded snapshot cells so the kernel can reach `KernelWorkerStatus.COMPLETE`.

## Workflow

### 1. Metadata & Push
- Ensure `kernel-metadata.json` has matching `id` (`<username>/<slug>`) and `title` (to avoid `409 Conflict` slug mismatches), with `"enable_gpu": true` and `"enable_internet": true`.
- Inject `.env` via a top `%%writefile .env` cell for batch runs.
- Push: `kaggle kernels push -p <dir>`.

### 2. Status & Log Inspection
- Check status: `kaggle kernels status <username>/<slug>`
- Download logs: `kaggle kernels output <username>/<slug> -p <out_dir>`
  - Inspect `<out_dir>/<slug>.log` (papermill JSONL log) and `<out_dir>/logs/llama_engine.log`.

## Self-Improvement Deployment Loop (LLM Server)
When deploying a notebook and starting an LLM inference backend on Kaggle Cloud, you MUST execute the following autonomous self-improvement loop until the server reaches `KernelWorkerStatus.COMPLETE` and inference is verified:

1. **Deploy & Launch**: Push the notebook via `kaggle kernels push -p <dir>`.
2. **Periodic Status & Log Monitoring**: Schedule periodic checks (`kaggle kernels status <username>/<slug>`).
3. **Investigate & Fix on Error**: If status is `KernelWorkerStatus.ERROR`, download logs via `kaggle kernels output`, diagnose the root cause (e.g., `CUDA::cuda_driver` missing, `libcudart.so.12` missing, Hugging Face 404 filename mismatch, OOM, path mismatch), and patch the notebook/config locally.
4. **Re-deploy & Re-verify**: Push the updated kernel and repeat steps 2–4 until `KernelWorkerStatus.COMPLETE` is achieved and inference output is confirmed in the logs.
5. **API Verification via `http.rest` & Report**: Once the inference server is running, test every API endpoint defined in `http.rest` (`/healthz`, `/api/v1/status`, `/v1/models`, `/v1/chat/completions`, etc.), and only report completion to the user after all API tests succeed.

## Private Dataset Utilization (Disk & Time Optimization)
- Kaggle's writable disk (`/kaggle/working` and `/tmp`) is limited. For large model weights (e.g., 20GB+ GGUF files) or heavy/slow-to-build artifacts, **prefer mounting them via a Kaggle Private Dataset** (`dataset_sources` in `kernel-metadata.json`, mounted read-only under `/kaggle/input/<dataset-slug>/`) instead of downloading or compiling them on every kernel run.
