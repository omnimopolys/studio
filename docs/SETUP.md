# Studio setup (one time, CEO)

## 1. Accounts and tools
1. Create the GitHub org `omnimopolys`: https://github.com/organizations/plan
2. Install tools: `sudo pacman -S github-cli rustup` then `rustup default stable`
3. Log in: `gh auth login` then `gh auth refresh -s project,admin:org,workflow`
4. Claude token: `claude setup-token` → copy the token.
5. Install the Claude GitHub App on the org: https://github.com/apps/claude
6. Discord: channel settings → Integrations → Webhooks → New → copy URL.
7. n8n Cloud: Settings → n8n API → Create API key.

## 2. GitHub token for agents and n8n (`AGENT_GH_TOKEN`)
Fine-grained token: https://github.com/settings/personal-access-tokens/new
- Resource owner: `omnimopolys`. Repositories: `omnimopolys/omnimopolys` (the game). Add each new game repo later. Expiry: 90 days or more.
- Repository permissions: Contents RW, Issues RW, Pull requests RW, Webhooks RW, Actions R, Metadata R.
- Organization permissions: Projects RW.
- Do **not** give "Workflows". This stops agents from changing CI.
- If the org must approve tokens: Org settings → Personal access tokens → approve.

Tip: create a separate GitHub user (e.g. `omnimopolys-bot`), add it to the org, and make the token there.
Then agent PRs show the bot name, not yours.

## 3. Run the scripts
```
cd /home/steve/dev/claude-projects/omnimopolys-studio
export CLAUDE_CODE_OAUTH_TOKEN=...   AGENT_GH_TOKEN=...
GAME_REPO=omnimopolys/omnimopolys scripts/setup-github.sh   # prints GITHUB_PROJECT_ID
# then copy templates/game-hook.yml into the game repo as .github/workflows/studio.yml

export N8N_URL=https://<you>.app.n8n.cloud  N8N_API_KEY=...
export DISCORD_WEBHOOK_URL=...  GITHUB_PROJECT_ID=...
scripts/n8n-deploy.sh
```
Start the commands with a space so zsh does not save the tokens in history
(needs `setopt HIST_IGNORE_SPACE`).

## 4. Test
1. Open a test issue → it appears on the board, triage agent labels it.
2. Start the work agent on the test issue:
   - Use a small, clear test issue, for example:
     "Add a `scripts/check.sh` that prints 'ok'."
   - Wait until the triage agent added `type:*`, `prio:*`, `area:*` labels (test 1).
     If it added `needs-human`, answer its questions first.
   - Add the label. Web: open the issue → right side "Labels" → gear icon →
     click `agent:ready` → click outside the box. Or terminal:
     `gh issue edit <N> --repo omnimopolys/omnimopolys --add-label agent:ready`
   - Watch, in this order:
     | Where | What you see | Time |
     |---|---|---|
     | n8n → Executions | "GitHub Router" run, green | seconds |
     | GitHub → Actions | "Studio" runs (job "work"); label becomes `agent:working` | 5–30 min |
     | Issue comments | Agent posts the PR link | at the end |
     | PR page | "studio / check" runs; "will merge automatically" | 5–15 min |
     | Issue / board / Discord | Issue closed, card "Done", "✅ Merged #…" | after CI |
   - If nothing starts: check n8n → Executions. No run → GitHub webhook missing (re-run `scripts/n8n-deploy.sh`).
     Red run → open it and read the error.
   - If the agent only comments questions: answer them, remove `agent:ready`, add it again.
3. n8n → Daily Report → "Execute workflow" → message in Discord.
4. Create milestone `v0.0.1 – Test`, close it → GitHub Release with notes + Discord post.
