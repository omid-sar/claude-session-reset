# claude-session-reset

Runs a daily Claude Code warm-up on a server at 10:00 UTC (6:00 AM Ottawa during EDT).

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
- Installs a cron entry at `0 10 * * *` using the resolved binary path.

## 3) Verify cron installation

```bash
crontab -l
```

You should see an entry similar to:

```cron
0 10 * * * cd /root/claude-session-reset && /usr/local/bin/claude -p "daily session warm-up: summarize any new TODOs in the current directory" --output-format text >> /root/claude-session-reset/logs/daily.log 2>&1
```

## 4) Manual test

```bash
bash ~/claude-session-reset/reset_session.sh
tail -n 50 ~/claude-session-reset/logs/daily.log
```
