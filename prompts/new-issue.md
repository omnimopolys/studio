Create a well-formed GitHub issue from this request: $ARGUMENTS

1. Check duplicates: `gh issue list --state all --search "<keywords>"`. If one exists, show it and stop.
2. Pick the type: bug, feature, task or docs.
3. Write a clear title (imperative, max 70 chars) and a body with:
   - Goal (why), Details (what), Acceptance criteria (checklist), Notes (files, GDD section).
4. `gh issue create --title "..." --body "..." --label "triage,type:<type>"`.
   Add `--milestone "<name>"` only if the request names one.
5. Print the issue URL. Do not add `agent:ready` unless the user asks.
