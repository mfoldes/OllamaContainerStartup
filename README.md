# Ollama Container Startup Script

## Purpose
Automates launching the `ollama/ollama` container with sensible defaults so you can quickly stand up a local Ollama instance. The script handles cleanup of any existing container, validates Docker prerequisites, picks the right runtime based on GPU availability, pulls required models, and optionally loads a user-selected model.

## Prerequisites
- Docker installed, running, and accessible to the current user.
- Internet access for `docker` pulls and Ollama REST calls.
- Optional: NVIDIA GPU with drivers, CUDA, and `nvidia-smi` (to enable `--gpus all`).

## Workflow
1. Verifies Docker is installed and running.
2. Stops/removes any existing `ollama` container.
3. Creates `ollama/` beside the script for persistent model state.
4. Uses the hardcoded `BEARER_TOKEN` (update this before sharing the server).
5. Picks GPU runtime if `nvidia-smi` succeeds; otherwise uses CPU-only mode.
6. Waits for Ollama to become ready on `localhost:11434`.
7. Ensures the models listed in the `models` array are available, pulling any missing.
8. Loads a chosen model—either from the first CLI argument or via an interactive prompt.

## Usage
Run the script from its directory or provide the path explicitly:

```bash
./start-ollama.sh                # interactive model selection
./start-ollama.sh llama3.1:8b    # load a specific model immediately
