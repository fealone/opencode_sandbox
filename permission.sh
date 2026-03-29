#!/bin/bash

# OpenCode Docker Permission Management Script
# Usage: ./permission.sh set /path/to/workspace

set -e

# GID of opencode user inside Docker
OPENCODE_GID=999

show_help() {
    cat << EOF
OpenCode Docker Permission Management Tool

Usage:
  $0 <command> [options]

Commands:
  set <workspace_dir>           Grant GID permissions to workspace directory
  check <workspace_dir>         Check current permissions
  restrict <workspace_dir> <file_pattern>   Remove GID permissions from files matching pattern
  unrestricted <workspace_dir> <file_pattern>  Remove restrictions from files matching pattern
  list <workspace_dir>          List restricted files

Options:
  -h, --help                   Show help

Examples:
  # Grant GID permissions to workspace
  $0 set /home/user/project

  # Check current permissions
  $0 check /home/user/project

  # Remove GID permissions from .env files
  $0 restrict /home/user/project "*.env"

  # Remove restrictions
  $0 unrestricted /home/user/project "*.env"

  # List restricted files
  $0 list /home/user/project

EOF
}

# Grant permissions
set_permissions() {
    local workspace_dir="$1"
    
    if [ -z "$workspace_dir" ]; then
        echo "Error: Workspace directory is required"
        echo "Usage: $0 set <workspace_dir>"
        exit 1
    fi
    
    if [ ! -d "$workspace_dir" ]; then
        echo "Error: Directory does not exist: $workspace_dir"
        exit 1
    fi
    
    echo "Setting permissions for: $workspace_dir"
    echo "GID: $OPENCODE_GID"
    echo "Permissions: rw-rw-r-- (664 for files, 775 for directories)"
    
    # Change GID only
    sudo chgrp -R $OPENCODE_GID "$workspace_dir"
    
    # Grant GID write permission to directories (for creating new files)
    sudo find "$workspace_dir" -type d -exec chmod 775 {} \;
    
    # Grant read/write permissions to files
    sudo find "$workspace_dir" -type f -exec chmod 664 {} \;
    
    echo "Permissions set successfully"
}

# Check permissions
check_permissions() {
    local workspace_dir="$1"
    
    if [ -z "$workspace_dir" ]; then
        echo "Error: Workspace directory is required"
        echo "Usage: $0 check <workspace_dir>"
        exit 1
    fi
    
    if [ ! -d "$workspace_dir" ]; then
        echo "Error: Directory does not exist: $workspace_dir"
        exit 1
    fi
    
    echo "=== Permission Check for: $workspace_dir ==="
    echo ""
    echo "Directory permissions:"
    ls -ld "$workspace_dir"
    echo ""
    echo "First level contents:"
    ls -la "$workspace_dir" | head -20
    echo ""
    echo "GID:"
    stat -c "GID: %g" "$workspace_dir"
    echo ""
    echo "Expected for Docker (opencode user):"
    echo "GID: $OPENCODE_GID"
}

# Restrict permissions
restrict_permissions() {
    local workspace_dir="$1"
    local pattern="$2"
    
    if [ -z "$workspace_dir" ] || [ -z "$pattern" ]; then
        echo "Error: Workspace directory and file pattern are required"
        echo "Usage: $0 restrict <workspace_dir> <file_pattern>"
        exit 1
    fi
    
    if [ ! -d "$workspace_dir" ]; then
        echo "Error: Directory does not exist: $workspace_dir"
        exit 1
    fi
    
    echo "Restricting pattern '$pattern' in $workspace_dir"
    
    # Remove GID permissions from files/directories matching the pattern
    local count=0
    while IFS= read -r item; do
        sudo chmod g-rw "$item"
        ((count++))
    done < <(find "$workspace_dir" -name "$pattern" \( -type f -o -type d \) 2>/dev/null)
    
    echo "Restricted $count item(s)"
}

# Unrestrict permissions
unrestrict_permissions() {
    local workspace_dir="$1"
    local pattern="$2"
    
    if [ -z "$workspace_dir" ] || [ -z "$pattern" ]; then
        echo "Error: Workspace directory and file pattern are required"
        echo "Usage: $0 unrestricted <workspace_dir> <file_pattern>"
        exit 1
    fi
    
    if [ ! -d "$workspace_dir" ]; then
        echo "Error: Directory does not exist: $workspace_dir"
        exit 1
    fi
    
    echo "Unrestricting pattern '$pattern' in $workspace_dir"
    
    # Grant GID permissions to files/directories matching the pattern
    local count=0
    while IFS= read -r item; do
        sudo chmod g+rw "$item"
        ((count++))
    done < <(find "$workspace_dir" -name "$pattern" \( -type f -o -type d \) 2>/dev/null)
    
    echo "Unrestricted $count item(s)"
}

# List restricted files
list_restrictions() {
    local workspace_dir="$1"
    
    if [ -z "$workspace_dir" ]; then
        echo "Error: Workspace directory is required"
        echo "Usage: $0 list <workspace_dir>"
        exit 1
    fi
    
    if [ ! -d "$workspace_dir" ]; then
        echo "Error: Directory does not exist: $workspace_dir"
        exit 1
    fi
    
    echo "=== Restricted Items in: $workspace_dir ==="
    echo ""
    
    # Display files/directories without GID read/write permissions
    local count=0
    while IFS= read -r item; do
        [ -n "$item" ] && { echo "$item"; count=$((count + 1)); }
    done < <(find "$workspace_dir" \( -type f -o -type d \) ! \( -perm -g+r -a -perm -g+w \) 2>/dev/null)
    
    echo ""
    echo "Total: $count item(s)"
}

# Main
if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

command="$1"
shift

case "$command" in
    set)
        set_permissions "$@"
        ;;
    check)
        check_permissions "$@"
        ;;
    restrict)
        restrict_permissions "$@"
        ;;
    unrestricted)
        unrestrict_permissions "$@"
        ;;
    list)
        list_restrictions "$@"
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "Error: Unknown command: $command"
        show_help
        exit 1
        ;;
esac
