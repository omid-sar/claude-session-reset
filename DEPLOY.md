# Deployment runbook

Set up the **Claude Code + Codex CLI** keepalive scheduler on a fresh server.
Replace `<SERVER_IP>` and `<DEPLOY_USER>` with your own values.

| Thing | Value |
|-------|-------|
| Server | `<SERVER_IP>` |
| Deploy user | `<DEPLOY_USER>` — a dedicated, unprivileged user |
| Repo | `omid-sar/claude-session-reset` (public) |
| Schedule | 5:00 AM + 10:02 AM Toronto EDT (`09:00` + `14:02` UTC) |

> **Security.** If this server also runs other sensitive or regulated workloads, run this
> automation under a **dedicated unprivileged user** that has no access to that data, and keep the
> keepalive prompts fixed and harmless. Don't point `claude`/`codex` at directories holding
> sensitive data. (Your real server IP and any such context belong in a private file, **not** in
> this public repo — see `DEPLOYMENT_NOTES.local.md`, which is gitignored.)

---

## How deployment works

"The scheduler" = **cron jobs on the server**. They exist only after `install.sh` runs *on the
server*. Two ways to get there:

- **Route B — manual.** SSH in, install, log in, run `install.sh`. Simplest; this is how it's set
  up today. **Recommended.**
- **Route A — GitHub auto-deploy.** Set 3 GitHub secrets; then every push to `main` SSHes in and
  re-runs `install.sh` automatically.

You log in to `claude`/`codex` on the server **once** in *both* routes — an interactive sign-in
can't be automated.

---

## Route B — manual setup

### 1. SSH in and create the dedicated user (as root/sudo)

```bash
ssh root@<SERVER_IP>
adduser --disabled-password --gecos "" <DEPLOY_USER>
```

### 2. Become the user and install Node (via nvm)

```bash
sudo -iu <DEPLOY_USER>
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
. ~/.nvm/nvm.sh && nvm install --lts
```

> nvm installs `node`/`npm` (and later `claude`/`codex`) under
> `~/.nvm/versions/node/<version>/bin/`. That's a long path, but `install.sh` finds the binaries
> automatically with `command -v` — you don't need to type the path anywhere.

### 3. Install the CLIs

```bash
npm install -g @anthropic-ai/claude-code @openai/codex
```

### 4. Log in (interactive — only a human can do this)

```bash
claude login
codex login
```

> **Gotcha we hit:** `claude login` / `codex login` may drop you straight into the program's
> full-screen chat. If the top of the screen already shows your account (e.g. "Welcome back …",
> a model name), you're **already signed in** — just leave: type `/exit` and Enter, or press
> **Ctrl+C twice**, to get back to the shell.
>
> Optional extra Claude accounts:
> ```bash
> CLAUDE_CONFIG_DIR=~/.claude-account2 claude login
> CLAUDE_CONFIG_DIR=~/.claude-account3 claude login
> ```

### 5. Clone and install the schedule

```bash
git clone https://github.com/omid-sar/claude-session-reset.git ~/claude-session-reset
cd ~/claude-session-reset
./install.sh        # prints: Installed cron jobs (claude x3 + codex): 5:00 AM and 10:02 AM ...
```

### 6. Prove it works (run the exact command cron will run)

```bash
bash ~/claude-session-reset/reset_session.sh && tail ~/claude-session-reset/logs/daily.log
bash ~/claude-session-reset/reset_session_codex.sh && tail ~/claude-session-reset/logs/codex.log
crontab -l          # should list 8 scheduled lines
```

Each of the first two should print a line containing **`OK`** and a UTC time. Because that's the
identical command cron runs each morning (same user, same paths), a success here guarantees the
schedule works. **Done.**

---

## Route A — GitHub auto-deploy (optional, do after Route B works)

You create one SSH keypair: the **public** half goes on the server (authorizes login), the
**private** half goes into a GitHub secret (lets the Action log in).

### A1. Create a dedicated deploy keypair — on your LOCAL machine

```bash
ssh-keygen -t ed25519 -C "keepalive-deploy" -f ~/.ssh/keepalive_deploy -N ""
```

- `~/.ssh/keepalive_deploy`     ← **private** key → GitHub secret
- `~/.ssh/keepalive_deploy.pub` ← **public** key → server
- `-N ""` = no passphrase — **required**, the Action logs in non-interactively.

> Don't reuse a **personal** SSH key (one that also unlocks your GitHub account or other servers)
> as the deploy secret — make a dedicated key so the blast radius is just `<DEPLOY_USER>`.

### A2. Put the PUBLIC key on the server (authorize `<DEPLOY_USER>`)

Print it locally, copy the single line:

```bash
cat ~/.ssh/keepalive_deploy.pub
```

On the SERVER (as root/sudo):

```bash
mkdir -p /home/<DEPLOY_USER>/.ssh
echo 'PASTE_THE_PUBLIC_KEY_LINE_HERE' >> /home/<DEPLOY_USER>/.ssh/authorized_keys
chmod 700 /home/<DEPLOY_USER>/.ssh
chmod 600 /home/<DEPLOY_USER>/.ssh/authorized_keys
chown -R <DEPLOY_USER>:<DEPLOY_USER> /home/<DEPLOY_USER>/.ssh
```

Test from your LOCAL machine (should print `connected as <DEPLOY_USER>`):

```bash
ssh -i ~/.ssh/keepalive_deploy <DEPLOY_USER>@<SERVER_IP> 'echo connected as $(whoami)'
```

### A3. Put the keys into GitHub secrets

```bash
gh secret set HETZNER_HOST    --repo omid-sar/claude-session-reset --body "<SERVER_IP>"
gh secret set HETZNER_USER    --repo omid-sar/claude-session-reset --body "<DEPLOY_USER>"
gh secret set HETZNER_SSH_KEY --repo omid-sar/claude-session-reset < ~/.ssh/keepalive_deploy
```

> The third command pipes the **private key file** in as the secret value (the one **without**
> `.pub`). `HETZNER_GITHUB_TOKEN` is not needed — the repo is public.
> Or use the web UI: repo → **Settings → Secrets and variables → Actions → New repository secret**.

### A4. Trigger a deploy

```bash
git push origin main      # any push to main runs .github/workflows/deploy.yml
```

Watch it under the repo's **Actions** tab. On success it has SSH'd in, pulled, and re-run
`install.sh`.

---

## Notes & gotchas (real things we ran into)

- **Login lands in the full-screen chat.** Exit with `/exit` or Ctrl+C twice (see step 4).
- **nvm path is long** but `install.sh` resolves `claude`/`codex` via `command -v` — no manual paths.
- **`account2` / `account3` Claude jobs are scheduled by default.** Only sign in the accounts you
  actually use; any account that isn't logged in just writes a harmless error each morning. If you
  use only one Claude account, remove the `account2`/`account3` cron lines from `install.sh`.
- **Codex is agentic.** To answer "what's the current time" it may run a quick `date` command. It's
  harmless and read-only. If you want it to run **no** commands at all, change the prompt in
  `reset_session_codex.sh` to a plain `"reply with the single word OK"`.
- **DST:** the cron times are fixed in UTC (`09:00` / `14:02`), which equals 5:00 / 10:02 AM Toronto
  during **EDT** (summer). In **EST** (winter) those become 4:00 / 9:02 AM Toronto. Adjust if you
  need exact local times year-round.
