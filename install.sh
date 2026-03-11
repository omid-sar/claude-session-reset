#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
RESET_SCRIPT="${SCRIPT_DIR}/reset_session.sh"
# 5:00 AM Toronto EDT (UTC-4) = 09:00 UTC
# 10:02 AM Toronto EDT (UTC-4) = 14:02 UTC
CRON_SCHEDULE_1="0 9 * * *"
CRON_SCHEDULE_2="2 14 * * *"

mkdir -p "${LOG_DIR}"
chmod +x "${RESET_SCRIPT}"

CLAUDE_BIN="$(command -v claude || true)"
if [[ -z "${CLAUDE_BIN}" ]]; then
  echo "Error: claude CLI not found in PATH. Install it before running install.sh." >&2
  exit 1
fi

CRON_CMD_1="${CRON_SCHEDULE_1} cd ${SCRIPT_DIR} && CLAUDE_BIN=${CLAUDE_BIN} ${RESET_SCRIPT}"
CRON_CMD_2="${CRON_SCHEDULE_2} cd ${SCRIPT_DIR} && CLAUDE_BIN=${CLAUDE_BIN} ${RESET_SCRIPT}"
CRON_CMD_A2_1="${CRON_SCHEDULE_1} ${SCRIPT_DIR}/reset_session_account2.sh"
CRON_CMD_A2_2="${CRON_SCHEDULE_2} ${SCRIPT_DIR}/reset_session_account2.sh"

CURRENT_CRONTAB="$(crontab -l 2>/dev/null || true)"
CLEANED_CRONTAB="$(
  printf '%s\n' "${CURRENT_CRONTAB}" \
    | grep -v 'reset_session' \
    | grep -v '^CRON_TZ=' \
    || true
)"

{
  printf '%s\n' "${CLEANED_CRONTAB}"
  printf '%s\n' "${CRON_CMD_1}"
  printf '%s\n' "${CRON_CMD_2}"
  printf '%s\n' "${CRON_CMD_A2_1}"
  printf '%s\n' "${CRON_CMD_A2_2}"
} | awk 'NF || !x++' | crontab -

echo "Installed cron jobs: 5:00 AM and 10:02 AM Toronto EDT."
crontab -l
