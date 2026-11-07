# How we work

1. **Issue.** Anyone opens an issue in the game repo.
2. **Triage (auto).** n8n adds the issue to the Roadmap board and starts the triage agent.
   The agent sets `type:*`, `prio:*`, `area:*` labels or asks questions (`needs-human`).
3. **Ready.** A team member adds `agent:ready`. n8n starts the work agent.
   Humans can also take the issue themselves (assign yourself, do not add `agent:ready`).
4. **PR.** Agent or human opens a PR with `Closes #N`. The check `studio / check` must pass. Agent PRs auto-merge.
5. **Release.** Close a milestone named like `v0.1.0 – Title`. n8n starts the release:
   release notes, GitHub Release, Discord post.

Talk to Claude: write `@claude <request>` in an issue or PR comment (write access needed).

| Label | Meaning |
|---|---|
| `type:bug` `type:feature` `type:task` `type:docs` | Kind of work |
| `prio:p0`..`prio:p3` | p0 = drop everything, p3 = nice to have |
| `area:sim` `area:render` `area:ui` `area:economy` `area:build` `area:web` | Part of the game |
| `triage` | Not triaged yet |
| `agent:ready` | Humans only: start the work agent |
| `agent:working` | Agent is working on it |
| `needs-human` | Agent is blocked; a human must decide |
