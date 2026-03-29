# OpenCode Docker Sandbox - Agent Guidelines

## Project Overview
Docker environment for running OpenCode in a sandboxed environment with isolated workspace access. Shell scripts manage permissions and container launches.

## Build/Lint/Test Commands

```bash
# Build Docker image
docker build -t opencode-sandbox .

# Run shellcheck for script linting
shellcheck run.sh permission.sh

# Validate bash syntax
bash -n run.sh && bash -n permission.sh

# Test scripts (manual verification)
./run.sh --help
./permission.sh --help
```

## Code Style Guidelines

### Shell Script Standards

**Shebang & Error Handling**
- Always use `#!/bin/bash` shebang
- Include `set -e` for exit-on-error
- Validate all arguments before use
- Provide clear error messages with usage instructions

**Variable Naming**
- UPPERCASE for configuration/environment variables: `OPENCODE_GID`, `WORKSPACE_DIR`, `CONFIG_FILE`
- UPPERCASE with underscores for constants
- camelCase for local variables: `workspace_dir`, `count`

**Function Naming**
- Use snake_case: `set_permissions()`, `check_permissions()`, `show_help()`
- Descriptive names indicating action and target

**Error Handling Pattern**
```bash
if [ -z "$variable" ]; then
    echo "Error: Variable is required"
    echo "Usage: $0 <args>"
    exit 1
fi

if [ ! -d "$directory" ]; then
    echo "Error: Directory does not exist: $directory"
    exit 1
fi
```

**Path Handling**
- Always quote variables: `"$WORKSPACE_DIR"`
- Convert to absolute paths when needed:
  ```bash
  WORKSPACE_DIR="$(cd "$WORKSPACE_DIR" && pwd)"
  ```
- Use `dirname` and `basename` for path manipulation

**Permissions & Security**
- GID 999 is reserved for `opencode` user
- Default permissions: 664 for files, 775 for directories
- Use `sudo` for permission changes
- Mount config files read-only: `:ro`

### Dockerfile Standards

**Base Image**: `node:20-slim`

**User Setup**
```dockerfile
RUN groupadd -r -g 999 opencode && useradd -r -g opencode opencode
USER opencode
```

**Labels**: Include maintainer and description in English

**Working Directory**: `/workspace`

### Script Structure

**run.sh** - Container launch script
- Validates workspace directory and config file
- Converts paths to absolute
- Supports `--import` option for session files
- Executes `docker run` with proper mounts

**permission.sh** - Permission management
- Commands: `set`, `check`, `restrict`, `unrestricted`, `list`
- Uses `find` with `-exec` for batch operations
- Provides help via heredoc

## Security Considerations

1. **Non-root execution**: Always run as `opencode` user (UID/GID 999)
2. **Read-only config**: Mount config files with `:ro` flag
3. **Read-only session files**: Mount session files with `:ro` flag
4. **Workspace isolation**: Only `/workspace` directory accessible
5. **Sensitive files**: Use `permission.sh restrict` for `.env`, credentials
6. **Input validation**: Always validate paths before mounting

## File Patterns

| File | Purpose |
|------|---------|
| `run.sh` | Docker container launcher |
| `permission.sh` | Permission management CLI |
| `Dockerfile` | Container definition |

## Common Operations

```bash
# Set workspace permissions before running
./permission.sh set /path/to/workspace

# Check permissions
./permission.sh check /path/to/workspace

# Run OpenCode
./run.sh /path/to/workspace /path/to/config.json

# Import session and launch
./run.sh /path/to/workspace /path/to/config.json --import /path/to/session.json

# Restrict sensitive files
./permission.sh restrict /path/to/workspace "*.env"
```

## Testing Approach

This project uses manual verification:
1. Syntax validation with `bash -n`
2. Linting with `shellcheck`
3. Functional testing by running scripts with various inputs
4. Docker image build verification

## Dependencies

- Docker (host)
- `opencode-ai` npm package (container)
- Standard Unix utilities: `find`, `chmod`, `chgrp`, `stat`
