#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/codex.log}"
CODEX_BIN="${CODEX_BIN:-codex}"
# Optional extra flags for hardening, e.g. CODEX_ARGS="--sandbox read-only"
CODEX_ARGS="${CODEX_ARGS:-}"
# Codex reads its config/auth from CODEX_HOME; set it in a wrapper for extra accounts.

mkdir -p "${LOG_DIR}"
cd "${SCRIPT_DIR}"

echo "=== $(date -u '+%Y-%m-%dT%H:%M:%SZ') ===" >> "${LOG_FILE}"
"${CODEX_BIN}" exec ${CODEX_ARGS} "session keepalive: reply with OK and the current UTC time" >> "${LOG_FILE}" 2>&1
echo "" >> "${LOG_FILE}"
