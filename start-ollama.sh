#!/bin/bash

# Function to check if Docker is installed and running
check_docker() {
  if ! command -v docker &> /dev/null; then
    echo "Docker command not found. Please ensure Docker is installed and running."
    exit 1
  fi
  if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
  fi
}

# Stops the container and removes the container
cleanup() {
  echo "Stopping and removing the Docker container..."
  docker stop ollama > /dev/null 2>&1
  docker rm ollama > /dev/null 2>&1
}

# Function to check for NVIDIA GPU (CUDA)
has_nvidia_gpu() {
  nvidia-smi > /dev/null 2>&1
  return $?
}

# Trap Ctrl+C (SIGINT) and call cleanup function
trap 'cleanup' SIGINT

# Check if Docker is installed and running
check_docker

# Cleanup Container Items before Restart
cleanup

# Get the script's root directory
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Create the ollama directory if it doesn't exist
mkdir -p "$SCRIPT_DIR/ollama"

# Generate a random bearer token
BEARER_TOKEN=$(openssl rand -hex 32)
echo "Generated Bearer token for authentication: Bearer $BEARER_TOKEN"

# Use existing BEARER_TOKEN
#BEARER_TOKEN=""
#echo "Using Bearer token : $BEARER_TOKEN for authentication"

# Check if NVIDIA support is available and start the container in background mode
if has_nvidia_gpu; then
  echo "NVIDIA GPU detected. Running with GPU support."
  docker run -d --gpus=all -v "$SCRIPT_DIR/ollama:/root/.ollama" -p 11434:11434 --name ollama -e BEARER_TOKEN="$BEARER_TOKEN" ollama/ollama
else
  echo "No CUDA compatible GPU found, running without GPU acceleration."
  docker run -d -v "$SCRIPT_DIR/ollama:/root/.ollama" -p 11434:11434 --name ollama -e BEARER_TOKEN="$BEARER_TOKEN" ollama/ollama
fi

# Wait for Ollama to be ready
echo "Waiting for Ollama to start..."
until curl -s http://localhost:11434 > /dev/null; do
  sleep 1
done
echo "Ollama started."

# Models to download if not exist
models=("phi3.5" "llama3.1:8b" "gpt-oss:20b")

for model in "${models[@]}"; do
  # Check if model exists
  if curl -s http://localhost:11434/api/tags | grep -q "\"name\":\"${model}:latest\""; then
    echo "${model} already exists."
  else
    echo "Pulling ${model}..."
    curl -X POST http://localhost:11434/api/pull -d "{\"name\": \"${model}\"}"
  fi
done

# Function to display model choices
select_model() {
  local choice
  read -p "Select a model by number (default is 1): " choice
  choice=${choice:-1}
  if ! [[ "$choice" =~ ^[1-4]$ ]]; then
    echo "Invalid choice. Defaulting to 1."
    choice=1
  fi
  echo "${models[$((choice - 1))]}"
}

# Determine model to load
if [[ -n "$1" ]]; then
  selected_model="$1"
  # Validate the provided model
  if [[ ! " ${models[*]} " =~ " ${selected_model} " ]]; then
    echo "Model '$selected_model' is not in the supported list."
    exit 1
  fi
else
  echo "Available models:"
  for i in "${!models[@]}"; do
    echo "$((i + 1)). ${models[$i]}"
  done
  selected_model=$(select_model)
  echo "You selected: $selected_model"
fi

echo "Selected model: $selected_model"

# load the selected model into Ollama
echo "Loading model '$selected_model' into Ollama..."
curl http://localhost:11434/api/generate -d '{
  "model": "'"${selected_model}"'"
}'
echo "Model '$selected_model' loaded."