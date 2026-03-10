#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
RESET_SCRIPT="${SCRIPT_DIR}/reset_session.sh"
CRON_TZ_VALUE="America/Toronto"
CRON_SCHEDULE="0 5 * * *"

mkdir -p "${LOG_DIR}"
chmod +x "${RESET_SCRIPT}"

CLAUDE_BIN="$(command -v claude || true)"
if [[ -z "${CLAUDE_BIN}" ]]; then
  echo "Error: claude CLI not found in PATH. Install it before running install.sh." >&2
  exit 1
fi

CRON_CMD="${CRON_SCHEDULE} cd ${SCRIPT_DIR} && CLAUDE_BIN=${CLAUDE_BIN} ${RESET_SCRIPT}"

CURRENT_CRONTAB="$(crontab -l 2>/dev/null || true)"
CLEANED_CRONTAB="$(
  printf '%s\n' "${CURRENT_CRONTAB}" \
    | grep -v 'reset_session.sh' \
    | grep -v "^CRON_TZ=${CRON_TZ_VALUE}$" \
    || true
)"

{
  printf '%s\n' "${CLEANED_CRONTAB}"
  printf '%s\n' "CRON_TZ=${CRON_TZ_VALUE}"
  printf '%s\n' "${CRON_CMD}"
} | awk 'NF || !x++' | crontab -

echo "Installed daily reset cron job at 5:00 AM ${CRON_TZ_VALUE}."
crontab -l
