#!/bin/bash
set -euo pipefail

# === Setup ===
ns="sandbox-nginx"
hpa_name="test-nginx"
svc_name="test-nginx"
editor="github-actions[bot]"

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
report_dir="./reports"
report_file="$report_dir/drift_report_${timestamp}.csv"

mkdir -p "$report_dir"
echo "timestamp,namespace,resource_type,resource_name,field,declared,observed,editor" > "$report_file"

# === Simulated entries — Replace these with actual parsed values ===
echo "$timestamp,$ns,HPA,$hpa_name,replicas,5,3,$editor" >> "$report_file"
echo "$timestamp,$ns,HPA,$hpa_name,cpu utilization,80%,50%,$editor" >> "$report_file"
echo "$timestamp,$ns,Service,$svc_name,targetPort,8080,80,$editor" >> "$report_file"

echo " Drift CSV written to: $report_file"

