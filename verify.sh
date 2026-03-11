#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG2="${SCRIPT_DIR}/logs/account2.log"
LOG_LINES_BEFORE=$(wc -l < "${LOG2}" 2>/dev/null || echo 0)

# Schedule both scripts for next minute
NEXT_MIN=$(date -u -d "+1 minute" "+%M %H" 2>/dev/null || date -u -v+1M "+%M %H")
TEST_ENTRY1="${NEXT_MIN} * * * /root/claude-session-reset/reset_session.sh"
TEST_ENTRY2="${NEXT_MIN} * * * /root/claude-session-reset/reset_session_account2.sh"

echo "Scheduling test run at $(date -u -d "+1 minute" "+%H:%M UTC" 2>/dev/null || date -u -v+1M "+%H:%M UTC")..."

# Back up current crontab and add test entries
crontab -l > /tmp/crontab_backup
{ crontab -l; echo "${TEST_ENTRY1}"; echo "${TEST_ENTRY2}"; } | crontab -

echo "Waiting 90 seconds..."
sleep 90

echo ""
echo "=== account1 log (last 5 lines) ==="
tail -n 5 "${SCRIPT_DIR}/logs/daily.log"

echo ""
echo "=== account2 log (last 5 lines) ==="
tail -n 5 "${LOG2}"

LOG_LINES_AFTER=$(wc -l < "${LOG2}" 2>/dev/null || echo 0)
if (( LOG_LINES_AFTER > LOG_LINES_BEFORE )); then
  echo ""
  echo "✓ account2 fired successfully"
else
  echo ""
  echo "✗ account2 log did not grow — check auth or path"
fi

# Restore original crontab
crontab /tmp/crontab_backup
echo "✓ crontab restored to original schedule"
crontab -l
