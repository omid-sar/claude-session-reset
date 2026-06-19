#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export CLAUDE_CONFIG_DIR="${HOME}/.claude-account2"
export CLAUDE_BIN="/usr/bin/claude"
export LOG_FILE="${SCRIPT_DIR}/logs/account2.log"

bash "${SCRIPT_DIR}/reset_session.sh"
