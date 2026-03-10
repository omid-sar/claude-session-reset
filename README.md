# claude-session-reset

Runs a daily Claude Code warm-up on a server at 5:00 AM Ottawa time (`America/Toronto`).

## 0) Prerequisites on server

Install and authenticate Claude Code CLI once:

```bash
npm install -g @anthropic-ai/claude-code
claude login
claude -p "say hello" --output-format text
```

## 1) Clone on your server

```bash
git clone https://github.com/YOUR_USERNAME/claude-session-reset.git ~/claude-session-reset
cd ~/claude-session-reset
```

## 2) Install the cron job

```bash
chmod +x install.sh reset_session.sh
./install.sh
```

What `install.sh` does:
- Creates `~/claude-session-reset/logs` if missing.
- Resolves the full path to `claude` using `command -v claude`.
- Installs `CRON_TZ=America/Toronto`.
- Installs a cron entry at `0 5 * * *` that runs `reset_session.sh` with the resolved `claude` path.

## 3) Verify cron installation

```bash
crontab -l
```

You should see an entry similar to:

```cron
CRON_TZ=America/Toronto
0 5 * * * cd /root/claude-session-reset && CLAUDE_BIN=/usr/local/bin/claude /root/claude-session-reset/reset_session.sh
```

## 4) Manual test

```bash
bash ~/claude-session-reset/reset_session.sh
tail -n 50 ~/claude-session-reset/logs/daily.log
```

## GitHub Actions deploy secrets

Required:
- `HETZNER_HOST`
- `HETZNER_USER`
- `HETZNER_SSH_KEY`

Optional for private repos:
- `HETZNER_GITHUB_TOKEN` (PAT with repo read access)
