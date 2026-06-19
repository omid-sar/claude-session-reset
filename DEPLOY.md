# Deployment runbook — new server (Helsinki)

Step-by-step setup for the keepalive scheduler on the **new** server.

| Thing | Value |
|-------|-------|
| Server IP | `62.238.42.138` (Hetzner CX43 "gp-automation", Helsinki) |
| Dedicated user | `aiwarm` (unprivileged, isolated from Oscar EMR) |
| Repo | `omid-sar/claude-session-reset` (public) |
| Schedule | 5:00 AM + 10:02 AM Toronto EDT (`09:00` + `14:02` UTC) |

> ⚠️ This box also runs **Oscar EMR** (patient data / PHI). Everything below runs as the
> unprivileged `aiwarm` user, which has **no access to EMR data**. Never run `claude`/`codex`
> from inside the Oscar directories, and keep the keepalive prompts fixed.

---

## How deployment actually works

"The scheduler" = **cron jobs on the server**. They only exist after `install.sh` runs *on the
server*. There are two ways to get there:

- **Route B — manual (this is what was done on the old server).** SSH in, install, log in, run
  `install.sh`. Simple, no secrets needed. **Recommended to start.**
- **Route A — GitHub auto-deploy.** Set 3 GitHub secrets; then every push to `main` SSHes into the
  server and re-runs `install.sh` automatically. (As of now this repo has **zero** secrets, so
  auto-deploy has never run — that's why the old box was set up by hand.)

You still log in to `claude`/`codex` on the server **once** in *both* routes — an interactive
sign-in can't be automated.

---

## Route B — manual setup (do this first)

### 1. SSH into the server as root (or your sudo user) and create the dedicated user

```bash
ssh root@62.238.42.138

adduser --disabled-password --gecos "" aiwarm
# (optional) give it a password if you want to su into it: passwd aiwarm
```

### 2. Become `aiwarm` and install the CLIs

```bash
sudo -iu aiwarm        # become the dedicated user

# Node.js (skip if already installed for this user). Example via nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
. ~/.nvm/nvm.sh && nvm install --lts

npm install -g @anthropic-ai/claude-code @openai/codex
```

### 3. Log in to each account (interactive — only you can do this)

```bash
claude login                                  # Claude account 1
CLAUDE_CONFIG_DIR=~/.claude-account2 claude login   # account 2
CLAUDE_CONFIG_DIR=~/.claude-account3 claude login   # account 3
codex login                                   # Codex account 1
```

### 4. Clone and install the cron jobs

```bash
git clone https://github.com/omid-sar/claude-session-reset.git ~/claude-session-reset
cd ~/claude-session-reset
./install.sh
```

### 5. Verify

```bash
crontab -l                                    # should list 8 entries (claude x3 + codex)

bash ~/claude-session-reset/reset_session.sh && tail ~/claude-session-reset/logs/daily.log
bash ~/claude-session-reset/reset_session_codex.sh && tail ~/claude-session-reset/logs/codex.log
```

If the last two print `OK …` (not an error), the scheduler is live. **You're done.**

---

## Route A — wire up GitHub auto-deploy (optional, do after Route B works)

This is the part about "pulling the keys and putting them in place." You create one SSH keypair:
the **public** half goes on the server (authorizes login), the **private** half goes into a GitHub
secret (lets the Action log in).

### A1. Create a dedicated deploy keypair — on your LOCAL machine

```bash
ssh-keygen -t ed25519 -C "gp-automation-deploy" -f ~/.ssh/gp_automation_deploy -N ""
```

- `~/.ssh/gp_automation_deploy`     ← **private** key (goes into the GitHub secret)
- `~/.ssh/gp_automation_deploy.pub` ← **public** key (goes on the server)
- `-N ""` = no passphrase — **required**, because the Action logs in non-interactively.

### A2. Put the PUBLIC key on the server (authorize `aiwarm`)

Print it locally and copy the single line:

```bash
cat ~/.ssh/gp_automation_deploy.pub
```

Then on the SERVER (as root/sudo), append it to `aiwarm`'s authorized keys:

```bash
mkdir -p /home/aiwarm/.ssh
echo 'PASTE_THE_PUBLIC_KEY_LINE_HERE' >> /home/aiwarm/.ssh/authorized_keys
chmod 700 /home/aiwarm/.ssh
chmod 600 /home/aiwarm/.ssh/authorized_keys
chown -R aiwarm:aiwarm /home/aiwarm/.ssh
```

Test the key from your LOCAL machine (should print `connected as aiwarm`):

```bash
ssh -i ~/.ssh/gp_automation_deploy aiwarm@62.238.42.138 'echo connected as $(whoami)'
```

### A3. Put the keys into GitHub secrets

Using the `gh` CLI (logged in as `omid-sar`):

```bash
gh secret set HETZNER_HOST    --repo omid-sar/claude-session-reset --body "62.238.42.138"
gh secret set HETZNER_USER    --repo omid-sar/claude-session-reset --body "aiwarm"
gh secret set HETZNER_SSH_KEY --repo omid-sar/claude-session-reset < ~/.ssh/gp_automation_deploy
```

> The third command pipes the **private key file** in as the secret value. Use the file **without**
> `.pub`. `HETZNER_GITHUB_TOKEN` is **not** needed — the repo is public.

Or via the web UI: repo → **Settings → Secrets and variables → Actions → New repository secret**,
and add the three names above (paste the full private key, including the
`-----BEGIN/END OPENSSH PRIVATE KEY-----` lines, for `HETZNER_SSH_KEY`).

Confirm they exist:

```bash
gh secret list --repo omid-sar/claude-session-reset
```

### A4. Trigger a deploy

```bash
git push origin main            # any push to main runs .github/workflows/deploy.yml
```

Watch it: repo → **Actions** tab, or `gh run watch`. On success it has SSH'd in, pulled, and
re-run `install.sh` for you.

---

## Security notes (PHI server)

- The deploy key authorizes **only `aiwarm`**, which is unprivileged and isolated from Oscar/EMR
  data — keep it that way (don't add this key to `root`).
- Keep `-N ""` (no passphrase) only for this dedicated deploy key; don't reuse a personal key.
- The keepalive jobs only send a fixed harmless prompt; they never read files or patient data.
