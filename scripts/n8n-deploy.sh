#!/usr/bin/env bash
# Deploys n8n/workflows/*.json to n8n Cloud. Safe to run again (updates by name).
# Needs env:  N8N_URL (e.g. https://yourname.app.n8n.cloud), N8N_API_KEY
# First run also needs: AGENT_GH_TOKEN, DISCORD_WEBHOOK_URL, GITHUB_PROJECT_ID
#   (setup-github.sh prints GITHUB_PROJECT_ID).
# Created credential IDs are stored in .n8n-state.env (gitignored, chmod 600).
set -euo pipefail
cd "$(dirname "$0")/.."

STATE=.n8n-state.env
# shellcheck disable=SC1090
[[ -f $STATE ]] && source "$STATE"
: "${N8N_URL:?set N8N_URL}" "${N8N_API_KEY:?set N8N_API_KEY}"
API="${N8N_URL%/}/api/v1"

api() {
  local method=$1 path=$2; shift 2
  curl -sfS -X "$method" "$API$path" \
    -H "X-N8N-API-KEY: $N8N_API_KEY" -H "Content-Type: application/json" "$@"
}
remember() {
  touch "$STATE"; chmod 600 "$STATE"
  grep -v "^$1=" "$STATE" > "$STATE.tmp" || true
  echo "$1=$2" >> "$STATE.tmp"; mv "$STATE.tmp" "$STATE"
}

# Target n8n project (not the personal space). Name can be changed with N8N_PROJECT.
if [[ -z "${N8N_PROJECT_ID:-}" ]]; then
  N8N_PROJECT_ID=$(api GET "/projects?limit=100" \
    | jq -r --arg n "${N8N_PROJECT:-Omnimopolys}" '.data[] | select(.name==$n) | .id' | head -1)
  [[ -n $N8N_PROJECT_ID ]] || { echo "n8n project '${N8N_PROJECT:-Omnimopolys}' not found"; exit 1; }
  remember N8N_PROJECT_ID "$N8N_PROJECT_ID"
fi

# transfer <workflows|credentials> <id>: move into the project. Already there → n8n refuses; that is fine.
transfer() {
  local code resp
  resp=$(mktemp)
  code=$(curl -sS -o "$resp" -w '%{http_code}' -X PUT "$API/$1/$2/transfer" \
    -H "X-N8N-API-KEY: $N8N_API_KEY" -H "Content-Type: application/json" \
    --data "{\"destinationProjectId\":\"$N8N_PROJECT_ID\"}") || code=000
  [[ $code == 2* ]] || echo "note: transfer $1/$2 → HTTP $code $(cat "$resp")" >&2
  rm -f "$resp"
}

if [[ -z "${N8N_GITHUB_CRED_ID:-}" ]]; then
  : "${AGENT_GH_TOKEN:?needed once to create the GitHub credential}"
  N8N_GITHUB_CRED_ID=$(jq -n --arg t "$AGENT_GH_TOKEN" \
    '{name:"GitHub omnimopolys",type:"githubApi",data:{server:"https://api.github.com",user:"omnimopolys",accessToken:$t}}' \
    | api POST /credentials --data-binary @- | jq -r .id)
  remember N8N_GITHUB_CRED_ID "$N8N_GITHUB_CRED_ID"
fi
if [[ -z "${N8N_DISCORD_CRED_ID:-}" ]]; then
  : "${DISCORD_WEBHOOK_URL:?needed once to create the Discord credential}"
  N8N_DISCORD_CRED_ID=$(jq -n --arg u "$DISCORD_WEBHOOK_URL" \
    '{name:"Discord omnimopolys",type:"discordWebhookApi",data:{webhookUri:$u}}' \
    | api POST /credentials --data-binary @- | jq -r .id)
  remember N8N_DISCORD_CRED_ID "$N8N_DISCORD_CRED_ID"
fi
: "${GITHUB_PROJECT_ID:?set GITHUB_PROJECT_ID (printed by scripts/setup-github.sh)}"
remember GITHUB_PROJECT_ID "$GITHUB_PROJECT_ID"
transfer credentials "$N8N_GITHUB_CRED_ID"
transfer credentials "$N8N_DISCORD_CRED_ID"

# deploy <file> <activate yes|no> → prints workflow id
deploy() {
  local file=$1 activate=$2 name body id
  name=$(jq -r .name "$file")
  body=$(sed -e "s/__GITHUB_CRED_ID__/$N8N_GITHUB_CRED_ID/g" \
             -e "s/__DISCORD_CRED_ID__/$N8N_DISCORD_CRED_ID/g" \
             -e "s/__PROJECT_ID__/$GITHUB_PROJECT_ID/g" \
             -e "s/__ERROR_WORKFLOW_ID__/${ERROR_ID:-}/g" "$file")
  id=$(api GET "/workflows?name=$(jq -rn --arg n "$name" '$n|@uri')" | jq -r '.data[0].id // empty')
  if [[ -n $id ]]; then
    printf '%s' "$body" | api PUT "/workflows/$id" --data-binary @- >/dev/null
  else
    id=$(printf '%s' "$body" | api POST /workflows --data-binary @- | jq -r .id)
  fi
  transfer workflows "$id"
  if [[ $activate == yes ]]; then api POST "/workflows/$id/activate" >/dev/null; fi
  echo "$name → $id" >&2
  echo "$id"
}

ERROR_ID=$(deploy n8n/workflows/error-alert.json no)
deploy n8n/workflows/github-router.json yes >/dev/null
deploy n8n/workflows/daily-report.json yes >/dev/null
echo "All n8n workflows deployed."
