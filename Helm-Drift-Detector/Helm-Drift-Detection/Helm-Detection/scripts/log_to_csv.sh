#!/usr/bin/env bash
# Convert drift.log -> CSV and store timestamped copies in reports/
# Columns: timestamp,namespace,resource_type,resource_name,field,declared,observed,editor
set -euo pipefail

ns="sandbox-nginx"
hpa_name="test-nginx"
svc_name="test-nginx"
editor="${GITHUB_ACTOR:-github-actions[bot]}"

in="drift.log"
ts_iso=$(date -u +%Y-%m-%dT%H:%M:%SZ)
ts_file=$(date -u +%Y%m%dT%H%M%SZ)

out="drift.csv"
out_dir="reports"
mkdir -p "$out_dir"

echo "timestamp,namespace,resource_type,resource_name,field,declared,observed,editor" > "$out"

if [ ! -s "$in" ]; then
  echo "$ts_iso,$ns,-,-,no_drift,-,-,$editor" >> "$out"
else
  prev_is_drift=0
  while IFS= read -r line || [ -n "$line" ]; do
    if echo "$line" | grep -qE '^[[:space:]]*DRIFT:'; then
      prev_is_drift=1
      continue
    fi
    if [ $prev_is_drift -eq 1 ]; then
      detail="$line"
      prev_is_drift=0

      field=$(echo "$detail" | awk -F'(' '{print $1}' | sed -E 's/[[:space:]]+$//')

      declared=$(echo "$detail" | sed -nE 's/.*[Ll]ocal=([^,]+).*/\1/p')
      observed=$(echo "$detail" | sed -nE 's/.*[Ll]ive=([^)]+).*/\1/p')
      [ -z "${declared:-}" ] && declared=$(echo "$detail" | sed -nE 's/.*[Dd]eclared=([^,]+).*/\1/p')
      [ -z "${observed:-}" ] && observed=$(echo "$detail" | sed -nE 's/.*[Oo]bserved=([^)]+).*/\1/p')
      declared=${declared:-"-"}; observed=${observed:-"-"}

      if echo "$field" | grep -qiE 'replica|cpu|averageUtilization'; then
        rt="HPA"; rn="$hpa_name"
      elif echo "$field" | grep -qiE 'port'; then
        rt="Service"; rn="$svc_name"
      else
        rt="Unknown"; rn="-"
      fi

      echo "$ts_iso,$ns,$rt,$rn,$field,$declared,$observed,$editor" >> "$out"
    fi
  done < "$in"

  lines=$(wc -l < "$out" | tr -d ' ')
  [ "$lines" -le 1 ] && echo "$ts_iso,$ns,-,-,no_drift,-,-,$editor" >> "$out"
fi

cp "$out" "$out_dir/drift_report_${ts_file}.csv"
[ -f "$in" ] && cp "$in" "$out_dir/drift_${ts_file}.log" || true

echo "CSV: $out_dir/drift_report_${ts_file}.csv"
