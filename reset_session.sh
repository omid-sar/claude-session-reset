#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${HOME}/claude-session-reset"
LOG_DIR="${REPO_DIR}/logs"
LOG_FILE="${LOG_DIR}/daily.log"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"

mkdir -p "${LOG_DIR}"

"${CLAUDE_BIN}" -p "daily session warm-up: summarize any new TODOs in the current directory" --output-format text >> "${LOG_FILE}" 2>&1
