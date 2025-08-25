#!/usr/bin/env bash
set -euo pipefail

DRIFT_LOG="${1:-drift.log}"
CSV_OUTPUT_FILE="${2:-reports/drift_history.csv}"
EDITOR="${3:-${GITHUB_ACTOR:-unknown}}"

: "${NAMESPACE:=sandbox-nginx}"
: "${HPA_NAME:=test-nginx}"
: "${SVC_NAME:=test-nginx}"

mkdir -p "$(dirname "$CSV_OUTPUT_FILE")"

# Create header if file does not exist
if [ ! -f "$CSV_OUTPUT_FILE" ]; then
  echo "timestamp,namespace,resource_type,resource_name,field,declared,observed,editor" > "$CSV_OUTPUT_FILE"
fi

ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# Parse "DRIFT:" blocks: expect the next non-empty line to contain:
# "<Field> (Local=X, Live=Y)"
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*DRIFT: ]]; then
    # read the next non-empty line
    read -r next || true
    # Skip blank lines between DRIFT: and the value line
    while [[ -n "${next:-}" && "${next// }" == "" ]]; do
      read -r next || true
    done

    # Extract: field, Local, Live
    # Examples:
    #   "minReplicas (Local=6, Live=1)"
    #   "Service TargetPort (Local=5050, Live=8080)"
    if [[ "${next:-}" =~ ^[[:space:]]*([^[:(]]+[^[:space:]])[[:space:]]*\(Local=([^,]+),[[:space:]]*Live=([^)]+)\) ]]; then
      field="${BASH_REMATCH[1]}"
      declared="$(echo "${BASH_REMATCH[2]}" | xargs)"
      observed="$(echo "${BASH_REMATCH[3]}" | xargs)"

      # Decide resource type/name based on the field label
      case "$field" in
        Service*|*Port*)
          resource_type="Service"
          resource_name="$SVC_NAME"
          ;;
        *)
          resource_type="HPA"
          resource_name="$HPA_NAME"
          ;;
      esac

      echo "$(ts),${NAMESPACE},${resource_type},${resource_name},${field},${declared},${observed},${EDITOR}" >> "$CSV_OUTPUT_FILE"
    fi
  fi
done < "$DRIFT_LOG"
