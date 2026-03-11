#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/daily.log}"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"

mkdir -p "${LOG_DIR}"
cd "${SCRIPT_DIR}"

echo "=== $(date -u '+%Y-%m-%dT%H:%M:%SZ') ===" >> "${LOG_FILE}"
"${CLAUDE_BIN}" -p "session keepalive: reply with OK and the current UTC time" --output-format text >> "${LOG_FILE}" 2>&1
echo "" >> "${LOG_FILE}"
