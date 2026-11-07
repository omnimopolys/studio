Write release notes for version $ARGUMENTS into the file `RELEASE_NOTES.md`.

1. Find the previous tag: `git describe --tags --abbrev=0` (none → use all history).
2. List merged PRs since then: `git log <prev>..HEAD --oneline` and `gh pr list --state merged --limit 100`.
3. Group into: Highlights (max 3, player view), New features, Fixes, Under the hood.
4. Write for players: short, plain English, no internal jargon. Link PRs as `#N`.
5. Only write `RELEASE_NOTES.md`. Do not commit, tag or push.
