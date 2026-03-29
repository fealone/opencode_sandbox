# OpenCode Docker Sandbox

A Docker environment for running OpenCode in a sandboxed environment with isolated workspace access.

## Features

- **Sandboxed Environment**: Only the mounted workspace directory is accessible
- **Non-root User**: Runs as `opencode` user for security
- **External Configuration**: OpenCode config file can be specified from outside
- **Clean Sessions**: Each session starts with a fresh environment
- **Session Import**: Import and continue from previous sessions

## Files

| File | Description |
|------|-------------|
| `Dockerfile` | OpenCode environment definition |
| `run.sh` | Launch script with workspace and config arguments |
| `permission.sh` | Permission management script for workspace |
| `packages.txt` | Additional packages to install in the container |

## Prerequisites

- Docker
- OpenCode configuration file (`opencode.json`)

## Quick Start

### 1. Build the Docker Image

```bash
docker build -t opencode-sandbox .
```

### 2. Set Workspace Permissions

Before running OpenCode, set permissions on your workspace directory:

```bash
# Grant GID permissions to workspace
./permission.sh set /path/to/workspace

# Check current permissions
./permission.sh check /path/to/workspace
```

### 3. Run OpenCode

```bash
./run.sh /path/to/workspace /path/to/opencode.json
```

Or use the `OPENCODE_CONFIG` environment variable:

```bash
OPENCODE_CONFIG=/path/to/opencode.json ./run.sh /path/to/workspace
```

### 4. Import a Session (Optional)

To continue from a previous session:

```bash
./run.sh /path/to/workspace /path/to/opencode.json --import /path/to/session.json
```

## Usage

### Basic Usage

```bash
./run.sh /path/to/workspace /path/to/config.json
```

### Import Session

```bash
./run.sh /path/to/workspace /path/to/config.json --import /path/to/session.json
```

### Arguments

1. **Workspace Directory** (required): The directory to mount as `/workspace` inside the container
2. **Config File Path** (optional): Path to the OpenCode configuration JSON file. If not provided, the `OPENCODE_CONFIG` environment variable will be used.

### Options

| Option | Description |
|--------|-------------|
| `--import <file>` | Import a session file before starting |
| `-h`, `--help` | Show help message |

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `OPENCODE_CONFIG` | Path to OpenCode configuration file | No (can use 2nd argument instead) |

## Permission Management

The `permission.sh` script helps manage file permissions for secure workspace access.

### How Permissions Work

OpenCode runs inside the container as the `opencode` user with GID 999. 
Workspace permissions are managed by setting the group ownership to GID 999, 
allowing the container to access files without requiring root privileges.

### Commands

```bash
# Grant GID permissions to workspace
./permission.sh set /path/to/workspace

# Check current permissions
./permission.sh check /path/to/workspace

# Restrict GID permissions for specific files (remove group read/write)
./permission.sh restrict /path/to/workspace "*.env"

# Remove restrictions
./permission.sh unrestricted /path/to/workspace "*.env"

# List all restricted files
./permission.sh list /path/to/workspace
```

### Security Note

By default, the workspace is mounted with full read/write access. Use `permission.sh restrict` to limit access to sensitive files like `.env`, `.git/credentials`, etc. Restrictions are applied directly to file permissions (state-based), not managed via a configuration file.

## Security

- Runs as non-root user (`opencode`) with UID/GID 999
- Permissions are managed via GID (group ID)
- Only the specified workspace directory is accessible
- Configuration file is mounted read-only
- No access to host system outside mounted volumes

## Base Image

- **Image**: `node:20-slim`
- **Package**: `opencode-ai@latest`

## Adding Custom Packages

To install additional packages in the container:

1. Edit `packages.txt` and add package names (one per line)
2. Rebuild the Docker image

```bash
# Edit packages.txt
echo "python3" >> packages.txt
echo "postgresql-client" >> packages.txt

# Rebuild image
docker build -t opencode-sandbox .
```

**Notes:**
- Use `apt` package names (e.g., `python3`, `nodejs`)
- Lines starting with `#` are treated as comments
- Empty lines are ignored
- The container will be rebuilt with the new packages

## License

MIT
