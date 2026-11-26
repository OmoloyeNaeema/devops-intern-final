#!/usr/bin/env bash
set -euo pipefail

echo "===== SYSTEM INFORMATION ====="

echo "Current User: $(id -un)"
echo "Effective UID: $(id -u)"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -sr)"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo
echo "===== DISK USAGE ====="
df -h /

echo 
echo "===== MEMORY USAGE ====="
free -h

echo 
echo "===== DOCKER STATUS ====="
if docker info >/dev/null 2>&1; then
    echo "Docker daemon is running."
else

    echo "Docker daemon is not running."
fi
