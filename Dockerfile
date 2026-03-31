FROM node:20-slim

# Metadata
LABEL maintainer="fealone@lonesec.com"
LABEL description="OpenCode sandbox environment"

# Install default packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    vim \
    curl \
    wget \
    tree \
    jq \
    htop \
    build-essential \
    shellcheck

# Install additional packages from packages.txt
COPY packages.txt /tmp/packages.txt
RUN if [ -s /tmp/packages.txt ]; then \
        grep -v '^#' /tmp/packages.txt | grep -v '^$' | xargs -r apt-get install -y --no-install-recommends || true; \
    fi && rm -f /tmp/packages.txt && rm -rf /var/lib/apt/lists/*

# Create group with GID 999 and user with home directory
RUN groupadd -r -g 999 opencode && \
    useradd -r -g opencode -d /home/opencode -m opencode

# Create directory for config files
RUN mkdir -p /home/opencode/.config/opencode && \
    chown -R opencode:opencode /home/opencode

# Working directory
WORKDIR /workspace

# Install OpenCode
RUN npm install -g opencode-ai@latest

# Set GID only
RUN chgrp -R opencode /workspace

# Switch to opencode user
USER opencode

# Configure git safe.directory for workspace
RUN git config --global --add safe.directory '/workspace'

# Default command
CMD ["opencode"]
