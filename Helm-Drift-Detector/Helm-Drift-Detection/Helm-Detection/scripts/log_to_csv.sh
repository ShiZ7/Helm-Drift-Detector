#!/usr/bin/env bash
set -euo pipefail
LOG_FILE="${1:?pass drift.log}"
CSV_OUT="${2:?pass output csv path}"

mkdir -p "$(dirname "$CSV_OUT")"

# Header: keep short, as requested (no delta/severity columns)
echo "timestamp,namespace,resource_type,resource_name,field,declared,observed,editor" > "$CSV_OUT"

TS="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
EDITOR="${GITHUB_ACTOR:-github-actions[bot]}"

# You told me the names already
NS="sandbox-nginx"
HPA_NAME="test-nginx"
SVC_NAME="test-nginx"

# Map field -> resource type/name (based on how detect-drift.sh prints fields)
map_field() {
  case "$1" in
    minReplicas|maxReplicas|"CPU Target") echo "HPA,$HPA_NAME" ;;
    "Service Port"|"Service TargetPort")  echo "Service,$SVC_NAME" ;;
    *)                                   echo "Unknown,unknown" ;;
  esac
}

# Each drift is two lines in the log:
# DRIFT:
# <Field> (Local=..., Live=...)
awk -v TS="$TS" -v NS="$NS" -v EDITOR="$EDITOR" '
  BEGIN { driftSeen=0 }
  /^DRIFT:/ { driftSeen=1; getline; line=$0;
    # split into: field and values
    field=line; sub(/ \(.*$/,"",field)
    local=""; live=""
    match(line,/Local=([^,)]*)/,a); if (a[1]!="") local=a[1];
    match(line,/Live=([^)]*)/,b);   if (b[1]!="")   live=b[1];

    # print a placeholder CSV row; resource gets filled by the shell mapper
    printf("%s\t%s\t%s\t%s\t%s\n", field, local, live, TS, NS);
  }
' "$LOG_FILE" | while IFS=$'\t' read -r FIELD LOCAL LIVE TS NS; do
  map=$(map_field "$FIELD")
  TYPE=${map%%,*}
  NAME=${map#*,}
  echo "$TS,$NS,$TYPE,$NAME,$FIELD,$LOCAL,$LIVE,$EDITOR" >> "$CSV_OUT"
done
