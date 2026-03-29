#!/bin/bash

# OpenCode Docker Launch Script
# Usage: ./run.sh /path/to/workspace [/path/to/config.json]

set -e

# Argument check
if [ $# -lt 1 ]; then
    echo "Error: Workspace directory is required"
    echo "Usage: $0 /path/to/workspace [/path/to/config.json]"
    exit 1
fi

WORKSPACE_DIR="$1"
CONFIG_FILE="${2:-$OPENCODE_CONFIG}"

# Config file check
if [ -z "$CONFIG_FILE" ]; then
    echo "Error: Config file is required"
    echo "  Either provide as second argument or set OPENCODE_CONFIG environment variable"
    echo "Usage: $0 /path/to/workspace [/path/to/config.json]"
    echo "       OPENCODE_CONFIG=/path/to/config.json $0 /path/to/workspace"
    exit 1
fi

# File/directory existence check
if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "Error: Workspace directory does not exist: $WORKSPACE_DIR"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file does not exist: $CONFIG_FILE"
    exit 1
fi

# Convert to absolute path
WORKSPACE_DIR="$(cd "$WORKSPACE_DIR" && pwd)"
CONFIG_FILE="$(cd "$(dirname "$CONFIG_FILE")" && pwd)/$(basename "$CONFIG_FILE")"

# Docker image name
IMAGE_NAME="opencode-sandbox"

# Execute Docker command
docker run -it --rm \
    --name opencode-session \
    -v "$WORKSPACE_DIR:/workspace" \
    -v "$CONFIG_FILE:/home/opencode/.config/opencode/opencode.json:ro" \
    -e OPENCODE_CONFIG=/home/opencode/.config/opencode/opencode.json \
    "$IMAGE_NAME"
