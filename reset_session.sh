#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${HOME}/claude-session-reset"
LOG_DIR="${REPO_DIR}/logs"
LOG_FILE="${LOG_DIR}/daily.log"

mkdir -p "${LOG_DIR}"

claude -p "daily session warm-up: summarize any new TODOs in the current directory" --output-format text >> "${LOG_FILE}" 2>&1
