#!/usr/bin/env bash
set -euo pipefail

DRIFT_LOG="${1:-drift.log}"
CSV_OUT="${2:-reports/drift_history.csv}"

mkdir -p "$(dirname "$CSV_OUT")"

# header once
if [ ! -f "$CSV_OUT" ]; then
  echo "timestamp,namespace,resource_type,resource_name,field,declared,observed,editor" > "$CSV_OUT"
fi

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
NS="${NS:-default}"
HPA="${HPA_NAME:-unknown}"
SVC="${SVC_NAME:-unknown}"
ED="${EDITOR:-unknown}"

awk -v ts="$TS" -v ns="$NS" -v hpa="$HPA" -v svc="$SVC" -v ed="$ED" '
/^DRIFT:/ {
  # the next line contains: "<Field> (Local=..., Live=...)"
  if (getline line) {
    if (match(line,/^[[:space:]]*([^ (][^ (]*)[[:space:]]*\(([^)]*)\)/,m)) {
      field=m[1]
      pairs=m[2]
      local=""; live=""
      n = split(pairs, kv, ",")
      for (i=1;i<=n;i++){
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", kv[i])
        split(kv[i], p, "=")
        if (p[1]=="Local") local=p[2]
        if (p[1]=="Live")  live=p[2]
      }
      # classify
      resType="HPA"; resName=hpa
      if (index(field,"Service")==1) { resType="Service"; resName=svc; sub(/^Service[[:space:]]+/,"",field) }
      printf "%s,%s,%s,%s,%s,%s,%s,%s\n", ts, ns, resType, resName, field, local, live, ed
    }
  }
}
' "$DRIFT_LOG" >> "$CSV_OUT"

echo "CSV written: $CSV_OUT"
