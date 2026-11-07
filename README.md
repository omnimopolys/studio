# Studio engine

Orchestration for game development with Claude agents. Not part of any game.

- **n8n Cloud = router.** Gets GitHub events, starts agents, posts to Discord, updates the Roadmap board.
- **GitHub Actions = hands.** `.github/workflows/studio.yml` (reusable) runs the agents: triage, work, `@claude` mentions, release notes. It also runs the game's `scripts/check.sh` as the required check.
- **Game repo = the game only.** It holds one thin hook file (`templates/game-hook.yml`) that calls this engine.

| Path | What |
|---|---|
| `.github/workflows/studio.yml` | Reusable agent workflow |
| `templates/game-hook.yml` | Copy into a game repo as `.github/workflows/studio.yml` |
| `prompts/` | Agent instructions (triage, work, release notes, new issue) |
| `n8n/workflows/` | n8n workflows (source of truth) |
| `scripts/setup-github.sh` | Prepare a game repo: labels, board, protection, secrets |
| `scripts/n8n-deploy.sh` | Deploy n8n workflows into the n8n project |
| `docs/SETUP.md` | One-time setup |
| `docs/PROCESS.md` | How humans and agents work together |

## Contract with a game repo
- The game has `CLAUDE.md` (tech and code rules) and `docs/design/GDD.md` (design).
- The game has `scripts/check.sh` (format, lint, test) once it has code. Agents create and keep it.
- The game repo has secrets `CLAUDE_CODE_OAUTH_TOKEN` and `AGENT_GH_TOKEN`.

## License
MIT or Apache-2.0, at your option.
