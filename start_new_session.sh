#!/bin/bash

# Script to start a new interactive session in the running 'opencode-session' container.

set -e

CONTAINER_NAME="opencode-session"

# Check if the container is running
if ! docker ps --filter "name=${CONTAINER_NAME}" --format "{{.ID}}" | grep -q .; then
    echo "Error: The container '${CONTAINER_NAME}' is not running."
    echo "Usage: ./run.sh /path/to/workspace /path/to/config.json"
    echo "Please start a session first using ./run.sh"
    exit 1
fi

echo "Starting a new shell in container '${CONTAINER_NAME}'..."

# Execute a new interactive shell in the container
docker exec -it "${CONTAINER_NAME}" opencode
