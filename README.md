# claude-session-reset

Runs daily warm-ups for **Claude Code** (3 accounts) and the **OpenAI Codex CLI** (1 account) on a server, at **5:00 AM and 10:02 AM Toronto time** (`America/Toronto`, EDT). Each run sends a single harmless keepalive prompt to keep the session/quota window active — it never reads files or touches application data.

> ⚠️ **Security note.** If your server also runs other sensitive or regulated workloads, run this automation under a **dedicated unprivileged user** that has no access to that data. Keep the keepalive prompts fixed and harmless, and never point `claude`/`codex` at directories holding sensitive data. (Keep your real server IP and any such context in a private file like `DEPLOYMENT_NOTES.local.md` — gitignored — not in this public repo.)

## 0) Prerequisites on server

### 0a) Create a dedicated, unprivileged user (recommended)

If this box also runs other sensitive workloads, run the keepalive as its own user with no access to that data:

```bash
sudo adduser --disabled-password --gecos "" aiwarm
sudo -iu aiwarm   # become the dedicated user for all steps below
```

### 0b) Install and authenticate the CLIs (as the dedicated user)

Claude Code — one login per account (repeat with a different `CLAUDE_CONFIG_DIR` for accounts 2 and 3):

```bash
npm install -g @anthropic-ai/claude-code
claude login
claude -p "say hello" --output-format text

CLAUDE_CONFIG_DIR=~/.claude-account2 claude login
CLAUDE_CONFIG_DIR=~/.claude-account3 claude login
```

OpenAI Codex CLI:

```bash
npm install -g @openai/codex
codex login
codex exec "say hello"
```

## 1) Clone on your server

```bash
git clone https://github.com/YOUR_USERNAME/claude-session-reset.git ~/claude-session-reset
cd ~/claude-session-reset
```

## 2) Install the cron jobs

```bash
chmod +x install.sh reset_session.sh
./install.sh
```

What `install.sh` does:
- Creates `logs/` if missing and makes the reset scripts executable.
- Resolves the full paths to `claude` and `codex` using `command -v`.
- Installs cron entries at `0 9 * * *` and `2 14 * * *` UTC (5:00 AM / 10:02 AM Toronto EDT) for all 3 Claude accounts plus Codex.
- If `codex` isn't installed yet, it warns and skips the codex jobs — install codex and re-run `install.sh` to enable them.

## 3) Verify cron installation

```bash
crontab -l
```

You should see entries similar to (times are UTC; `09:00` = 5:00 AM, `14:02` = 10:02 AM Toronto EDT):

```cron
0 9 * * * cd /home/aiwarm/claude-session-reset && CLAUDE_BIN=/usr/bin/claude /home/aiwarm/claude-session-reset/reset_session.sh
2 14 * * * cd /home/aiwarm/claude-session-reset && CLAUDE_BIN=/usr/bin/claude /home/aiwarm/claude-session-reset/reset_session.sh
0 9 * * * /home/aiwarm/claude-session-reset/reset_session_account2.sh
0 9 * * * /home/aiwarm/claude-session-reset/reset_session_account3.sh
0 9 * * * cd /home/aiwarm/claude-session-reset && CODEX_BIN=/usr/bin/codex /home/aiwarm/claude-session-reset/reset_session_codex.sh
2 14 * * * cd /home/aiwarm/claude-session-reset && CODEX_BIN=/usr/bin/codex /home/aiwarm/claude-session-reset/reset_session_codex.sh
```

## 4) Manual test

```bash
bash ~/claude-session-reset/reset_session.sh
tail -n 50 ~/claude-session-reset/logs/daily.log

bash ~/claude-session-reset/reset_session_codex.sh
tail -n 50 ~/claude-session-reset/logs/codex.log
```

## Adding more Codex accounts later

Mirror the Claude wrappers. Create `reset_session_codex_account2.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CODEX_HOME="${HOME}/.codex-account2"
export LOG_FILE="${SCRIPT_DIR}/logs/codex-account2.log"
bash "${SCRIPT_DIR}/reset_session_codex.sh"
```

Authenticate it once with `CODEX_HOME=~/.codex-account2 codex login`, then add cron lines for it in `install.sh`.

## GitHub Actions deploy secrets

On every push to `main`, the workflow SSHes into the server and re-runs `install.sh`. Point these at the **new** server:

Required:
- `HETZNER_HOST` — your server's IP address
- `HETZNER_USER` — the dedicated user (e.g. `aiwarm`)
- `HETZNER_SSH_KEY` — private key authorized for that user

Optional for private repos:
- `HETZNER_GITHUB_TOKEN` (PAT with repo read access)
