---
name: kaggle-operator
description: Operate Kaggle Cloud environments via the `kaggle` CLI: push GPU notebooks, monitor batch kernel execution, retrieve logs, and run an autonomous self-improvement loop until LLM inference servers are verified healthy.
---

# Skill: Kaggle Cloud Session & Deployment Operator

Operate Kaggle Cloud environments via the `kaggle` CLI to deploy notebooks and run LLM inference backends.

---

## 1. Core Principles (Kaggle vs. Colab)

- **Asynchronous Batch Execution**: `kaggle kernels push -p <dir>` triggers an async batch run via `papermill`. There is no persistent CLI REPL.
- **Working Directory Discipline**: Everything in `/kaggle/working` is archived as kernel output. Always store `.venv` and model weights in `/tmp/` (`VENV_DIR=/tmp/.venv`, `MODELS_DIR=/tmp/models`).
- **Finite Run Design**: Replace infinite loops (`while True:`) with finite status snapshots so the kernel reaches `KernelWorkerStatus.COMPLETE`.
- **Private Datasets**: Mount 20GB+ GGUF models or heavy prebuilt artifacts via `dataset_sources` under `/kaggle/input/<dataset-slug>/`.

---

## 2. Standard CLI Operations

| Step | Command | Purpose |
| :--- | :--- | :--- |
| **1. Push** | `kaggle kernels push -p <dir>` | Deploy notebook + `kernel-metadata.json` (requires matching `id` and `title`, `"enable_gpu": true`, `"enable_internet": true`). |
| **2. Status** | `kaggle kernels status <username>/<slug>` | Monitor execution state (`RUNNING` / `COMPLETE` / `ERROR`). |
| **3. Output** | `kaggle kernels output <username>/<slug> -p <out_dir>` | Retrieve execution logs (`<slug>.log` and `logs/`). |

---

## 3. Autonomous Self-Improvement Deployment Loop

When launching an LLM inference backend, execute this loop autonomously until verified:

```
[Deploy: push] -> [Monitor: status] ──(COMPLETE)──> [Verify: http.rest] ──(PASS)──> [Report to User]
                         │                                 │
                      (ERROR)                           (FAIL)
                         ▼                                 ▼
               [Diagnose: output logs] ──> [Fix locally] ──┘
```

1. **Deploy**: Push notebook and metadata via `kaggle kernels push -p <dir>`.
2. **Monitor**: Periodically poll status (`kaggle kernels status`).
3. **Diagnose on Error**: If `KernelWorkerStatus.ERROR`, download logs via `kaggle kernels output` and resolve root causes:
   - Missing `CUDA::cuda_driver` or `libcudart.so.12` → Switch to prebuilt wheels or official static binaries.
   - Hugging Face 404 → Verify real model filenames via HF tree API.
   - OOM (Error 137) → Reduce context length, adjust GPU offloading, or eliminate parallel compiler flags (`-j`).
4. **Re-deploy**: Patch locally and push again until `KernelWorkerStatus.COMPLETE`.
5. **API Verification & Report**: Test all endpoints via `http.rest` (`/healthz`, `/api/v1/status`, `/v1/models`, `/v1/chat/completions`). Report completion only after all tests succeed.
