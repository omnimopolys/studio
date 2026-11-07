#!/usr/bin/env bash
# Prepares a game repo for the studio engine. Safe to run again.
# Needs: gh (logged in with scopes repo, workflow, project, admin:org).
# Env:  GAME_REPO (default omnimopolys/omnimopolys), PROJECT_TITLE, MILESTONE
#       CLAUDE_CODE_OAUTH_TOKEN, AGENT_GH_TOKEN (optional) → stored as repo secrets.
set -euo pipefail

FULL=${GAME_REPO:-omnimopolys/omnimopolys}
ORG=${FULL%%/*}
PROJECT_TITLE=${PROJECT_TITLE:-"Omnimopolys Roadmap"}
MILESTONE=${MILESTONE:-"v0.1.0 – First playable"}
HOOK="$(dirname "$0")/../templates/game-hook.yml"

echo "== Repository $FULL"
gh repo view "$FULL" >/dev/null 2>&1 || gh repo create "$FULL" --public --add-readme
gh repo edit "$FULL" \
  --enable-auto-merge --enable-squash-merge \
  --enable-merge-commit=false --enable-rebase-merge=false \
  --delete-branch-on-merge --enable-wiki=false

echo "== Labels"
label() { gh label create "$1" --repo "$FULL" --color "$2" --description "$3" --force >/dev/null; }
label "type:bug"      d73a4a "Something does not work"
label "type:feature"  0e8a16 "New feature or change"
label "type:task"     c5def5 "Technical or chore work"
label "type:docs"     0075ca "Documentation or design doc"
label "prio:p0"       b60205 "Drop everything"
label "prio:p1"       d93f0b "Next up"
label "prio:p2"       fbca04 "Normal"
label "prio:p3"       fef2c0 "Nice to have"
for a in sim render ui economy build web; do label "area:$a" 5319e7 "Area: $a"; done
label "triage"        ededed "Not triaged yet"
label "agent:ready"   1d76db "Humans only: start the work agent"
label "agent:working" 0052cc "Agent is working on it"
label "needs-human"   e99695 "Blocked: a human must decide"

echo "== Milestone"
if ! gh api "repos/$FULL/milestones?state=all" --jq '.[].title' | grep -qxF "$MILESTONE"; then
  gh api "repos/$FULL/milestones" -f title="$MILESTONE" \
    -f description="Close this milestone to start a release." >/dev/null
fi

echo "== Project"
PROJ=$(gh project list --owner "$ORG" --format json --jq ".projects[] | select(.title==\"$PROJECT_TITLE\") | .number")
if [[ -z "$PROJ" ]]; then
  PROJ=$(gh project create --owner "$ORG" --title "$PROJECT_TITLE" --format json --jq .number)
fi
gh project link "$PROJ" --owner "$ORG" --repo "$FULL" >/dev/null 2>&1 || true
PROJECT_ID=$(gh project view "$PROJ" --owner "$ORG" --format json --jq .id)
echo "Project #$PROJ id=$PROJECT_ID"

echo "== Branch protection (main: 'studio / check' must pass)"
gh api -X PUT "repos/$FULL/branches/main/protection" --input - >/dev/null <<JSON
{
  "required_status_checks": { "strict": false, "contexts": ["studio / check"] },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON

echo "== Secrets"
for s in CLAUDE_CODE_OAUTH_TOKEN AGENT_GH_TOKEN; do
  if [[ -n "${!s:-}" ]]; then
    printf '%s' "${!s}" | gh secret set "$s" --repo "$FULL"
    echo "set $s"
  elif gh secret list --repo "$FULL" | grep -q "^$s"; then
    echo "$s already set"
  else
    echo "MISSING $s – export it and run again"
  fi
done

echo "== Hook file"
if gh api "repos/$FULL/contents/.github/workflows/studio.yml" >/dev/null 2>&1; then
  echo "hook present"
else
  echo "MISSING: copy $HOOK to $FULL as .github/workflows/studio.yml and push it."
fi

echo
echo "Done. Project board: https://github.com/orgs/$ORG/projects/$PROJ/workflows"
echo "  → turn on 'Item closed' and 'Pull request merged' (set Status: Done)."
echo "For n8n deploy: export GITHUB_PROJECT_ID=$PROJECT_ID"
