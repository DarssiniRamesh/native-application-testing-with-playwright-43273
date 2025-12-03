#!/usr/bin/env bash
set -euo pipefail
IMG="native_application"
DIR="native-application-testing-with-playwright-43273/native_application"
docker build -f "$DIR/Dockerfile" -t "$IMG" .
echo "Built image: $IMG"
