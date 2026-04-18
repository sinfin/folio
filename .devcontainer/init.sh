#!/usr/bin/env bash
# Runs on the host before the container starts (devcontainer.json initializeCommand).
# Opt-in: if ~/.tmux.conf exists, stage it for bootstrap.sh to copy into the
# container. Absent on the host: skip silently.
mkdir -p .devcontainer/tmp
cp ~/.tmux.conf .devcontainer/tmp/tmux.conf 2>/dev/null || true
