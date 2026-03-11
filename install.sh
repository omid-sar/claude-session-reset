#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
RESET_SCRIPT="${SCRIPT_DIR}/reset_session.sh"
# UTC times for every 5 hours starting at 5 AM Toronto EDT (UTC-4):
# 05 AM EDT=09 UTC, 10 AM EDT=14 UTC, 03 PM EDT=19 UTC, 08 PM EDT=00 UTC, 01 AM EDT=05 UTC
# In winter (EST, UTC-5) these fire one hour earlier local time — adjust to 0 4,9,14,19 if needed
CRON_SCHEDULE="0 0,5,9,14,19 * * *"

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
    | grep -v '^CRON_TZ=' \
    || true
)"

{
  printf '%s\n' "${CLEANED_CRONTAB}"
  printf '%s\n' "${CRON_CMD}"
} | awk 'NF || !x++' | crontab -

echo "Installed cron job: every 5 hours from 5 AM Toronto EDT (UTC schedule: ${CRON_SCHEDULE})."
crontab -l
