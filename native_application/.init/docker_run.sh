#!/usr/bin/env bash
set -euo pipefail
IMG="${1:-native_application}"
# Run container as root user (default)
docker run --rm -it -p 8080:8080 "$IMG"
