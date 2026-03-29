#!/bin/bash

# OpenCode Docker Launch Script
# Usage: ./run.sh /path/to/workspace [/path/to/config.json] [--import /path/to/session.json]

set -e

SESSION_FILE=""

show_help() {
    cat << EOF
OpenCode Docker Launch Script

Usage:
  $0 /path/to/workspace [/path/to/config.json] [--import /path/to/session.json]

Arguments:
  /path/to/workspace           Working directory path (required)
  /path/to/config.json         Configuration file path (optional, or use OPENCODE_CONFIG env var)

Options:
  --import <file>              Import a session file before starting
  -h, --help                   Show this help message

Examples:
  # Normal launch
  $0 /path/to/workspace /path/to/config.json

  # Import session and launch
  $0 /path/to/workspace /path/to/config.json --import /path/to/session.json

  # Using environment variable for config
  OPENCODE_CONFIG=/path/to/config.json $0 /path/to/workspace

  # Import session without explicit config
  OPENCODE_CONFIG=/path/to/config.json $0 /path/to/workspace --import /path/to/session.json
EOF
}

# Parse arguments
if [ $# -lt 1 ]; then
    echo "Error: Workspace directory is required"
    echo "Usage: $0 /path/to/workspace [/path/to/config.json] [--import /path/to/session.json]"
    exit 1
fi

WORKSPACE_DIR=""
CONFIG_FILE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --import)
            if [ -z "$2" ]; then
                echo "Error: --import requires a session file path"
                exit 1
            fi
            SESSION_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            if [ -z "$WORKSPACE_DIR" ]; then
                WORKSPACE_DIR="$1"
            elif [ -z "$CONFIG_FILE" ]; then
                CONFIG_FILE="$1"
            fi
            shift
            ;;
    esac
done

# Config file check
if [ -z "$CONFIG_FILE" ]; then
    CONFIG_FILE="$OPENCODE_CONFIG"
fi

if [ -z "$CONFIG_FILE" ]; then
    echo "Error: Config file is required"
    echo "  Either provide as second argument or set OPENCODE_CONFIG environment variable"
    echo "Usage: $0 /path/to/workspace [/path/to/config.json] [--import /path/to/session.json]"
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

# Session file check
if [ -n "$SESSION_FILE" ]; then
    if [ ! -f "$SESSION_FILE" ]; then
        echo "Error: Session file does not exist: $SESSION_FILE"
        exit 1
    fi
fi

# Convert to absolute path
WORKSPACE_DIR="$(cd "$WORKSPACE_DIR" && pwd)"
CONFIG_FILE="$(cd "$(dirname "$CONFIG_FILE")" && pwd)/$(basename "$CONFIG_FILE")"

if [ -n "$SESSION_FILE" ]; then
    SESSION_FILE="$(cd "$(dirname "$SESSION_FILE")" && pwd)/$(basename "$SESSION_FILE")"
fi

# Docker image name
IMAGE_NAME="opencode-sandbox"

# Execute Docker command
if [ -n "$SESSION_FILE" ]; then
    docker run -it --rm \
        --name opencode-session \
        -v "$WORKSPACE_DIR:/workspace" \
        -v "$CONFIG_FILE:/home/opencode/.config/opencode/opencode.json:ro" \
        -v "$SESSION_FILE:/tmp/session.json:ro" \
        -e OPENCODE_CONFIG=/home/opencode/.config/opencode/opencode.json \
        "$IMAGE_NAME" \
        sh -c "opencode import /tmp/session.json && opencode"
else
    docker run -it --rm \
        --name opencode-session \
        -v "$WORKSPACE_DIR:/workspace" \
        -v "$CONFIG_FILE:/home/opencode/.config/opencode/opencode.json:ro" \
        -e OPENCODE_CONFIG=/home/opencode/.config/opencode/opencode.json \
        "$IMAGE_NAME"
fi
