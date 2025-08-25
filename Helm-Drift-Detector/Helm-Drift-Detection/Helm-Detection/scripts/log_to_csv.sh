#!/usr/bin/env bash
# Usage: log_to_csv.sh <drift.log> <out.csv>
set -euo pipefail

DRIFT_LOG="${1:-drift.log}"
OUT="${2:-reports/drift_report.csv}"

# Optional envs to improve CSV (fallbacks if not provided)
NS="${NS:-sandbox-nginx}"
HPA_NAME="${HPA_NAME:-test-nginx}"
SVC_NAME="${SVC_NAME:-test-nginx}"
EDITOR="${EDITOR:-github-actions[bot]}"

mkdir -p "$(dirname "$OUT")"
if [[ ! -f "$OUT" ]]; then
  echo "timestamp,namespace,resource_type,resource_name,field,declared,observed,editor" > "$OUT"
fi

ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# Parse lines like:
#  DRIFT:
#  minReplicas (Local=6, Live=1)
#  maxReplicas (Local=12, Live=5)
#  CPU Target (Local=99%, Live=100%)
#  Service Port (Local=77, Live=80)
#  Service TargetPort (Local=7070, Live=8080)
#
# We infer resource type from the field label.
while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*DRIFT: ]] && continue

  if [[ "$line" =~ Local=([^,]+),[[:space:]]Live=([^)]+)\) ]]; then
    local_val="${BASH_REMATCH[1]}"
    live_val="${BASH_REMATCH[2]}"

    # Extract field label before '(' and trim
    field="$(sed -E 's/[[:space:]]*\((.*)//' <<<"$line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"

    if [[ "$field" == Service* ]]; then
      rtype="Service"
      rname="$SVC_NAME"
      field_label="${field#Service }"
    else
      rtype="HPA"
      rname="$HPA_NAME"
      field_label="$field"
    fi

    echo "$(ts),$NS,$rtype,$rname,$field_label,$local_val,$live_val,$EDITOR" >> "$OUT"
  fi
done < <(grep -E 'DRIFT:|Local=|Live=' -A1 "$DRIFT_LOG" | sed 's/^--$//')
