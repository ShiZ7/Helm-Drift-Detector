#!/usr/bin/env bash
set -euo pipefail

DRIFT_OUTPUT_FILE="${1:-drift.log}"
CSV_OUTPUT_FILE="${2:-drift_report.csv}"

# Initialize CSV if missing
if [[ ! -f "$CSV_OUTPUT_FILE" ]]; then
  echo "timestamp,namespace,resource_type,resource_name,field,declared,observed,editor" > "$CSV_OUTPUT_FILE"
fi

# Editor: PR author if available, else default bot
EDITOR="${GITHUB_ACTOR:-github-actions[bot]}"

# Extract lines starting with 'DRIFT:' and convert to CSV rows
# Expected log fragments produced by detect-drift.sh:
#   DRIFT:
#   minReplicas (Local=6, Live=1)
#   ...
#   Service TargetPort (Local=7070, Live=8080)
#
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
ns="sandbox-nginx"
hpa="test-nginx"
svc="test-nginx"

awk -v TS="$ts" -v NS="$ns" -v HPA="$hpa" -v SVC="$svc" -v EDIT="$EDITOR" '
  BEGIN { inblock=0; }
  /^DRIFT:/ { inblock=1; next }
  inblock && NF {
    line=$0
    gsub(/\r/,"",line)
    # match: Field (Local=VAL, Live=VAL)
    if (match(line, /^([^()]+) *\(([^)]+)\)/, m)) {
      field=m[1]; details=m[2]
      # pick resource type/name based on known fields
      rtype="HPA"; rname=HPA
      if (index(field,"Service ")==1) { rtype="Service"; rname=SVC; sub(/^Service /,"",field) }
      # extract Local and Live
      local=""; live=""
      n=split(details, kv, /, */)
      for (i=1;i<=n;i++) {
        split(kv[i], p, /=/)
        key=p[1]; val=p[2]
        if (key=="Local") local=val
        if (key=="Live")  live=val
      }
      gsub(/[%]/,"%",local); gsub(/[%]/,"%",live)
      # print CSV row
      printf("%s,%s,%s,%s,%s,%s,%s,%s\n", TS, NS, rtype, rname, field, local, live, EDIT);
    }
    next
  }
' "$DRIFT_OUTPUT_FILE" >> "$CSV_OUTPUT_FILE"

echo "CSV written: $CSV_OUTPUT_FILE"
