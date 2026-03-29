FROM node:20-slim

# Metadata
LABEL maintainer="opencode-docker"
LABEL description="OpenCode sandbox environment"

# Create group with GID 999
RUN groupadd -r -g 999 opencode && useradd -r -g opencode opencode

# Create directory for config files
RUN mkdir -p /home/opencode/.config/opencode && \
    chgrp -R opencode /home/opencode

# Working directory
WORKDIR /workspace

# Install OpenCode
RUN npm install -g opencode-ai@latest

# Set GID only
RUN chgrp -R opencode /workspace

# Switch to opencode user
USER opencode

# Default command
CMD ["opencode"]
