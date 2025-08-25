#!/bin/bash

DRIFT_OUTPUT_FILE="${1:-drift.log}"
CSV_OUTPUT_FILE="${2:-drift_history.csv}"

# Initialize CSV if it doesn't exist
if [ ! -f "$CSV_OUTPUT_FILE" ]; then
  echo "timestamp,namespace,resource_type,resource_name,field,declared,observed,editor" > "$CSV_OUTPUT_FILE"
fi

# Extract DRIFT lines from log and convert to CSV
grep "DRIFT:" "$DRIFT_OUTPUT_FILE" | while IFS= read -r line; do
  timestamp=$(date +'%Y-%m-%dT%H:%M:%SZ')
  namespace="sandbox-nginx"  # Adjust this as per your environment
  resource_type="HPA"  # Adjust as needed based on your setup (e.g., HPA, Service)
  resource_name=$(echo "$line" | grep -oP '(?<=HPA/)[^ ]*')  # Adjust based on the line
  field=$(echo "$line" | cut -d ':' -f2 | cut -d '(' -f1 | xargs) 
  declared=$(echo "$line" | grep -oP '(?<=declared=)[^,]*')
  observed=$(echo "$line" | grep -oP '(?<=observed=)[^,]*')
  editor=$(echo "$line" | grep -oP '(?<=editor=)[^,]*')

  echo "$timestamp,$namespace,$resource_type,$resource_name,$field,$declared,$observed,$editor" >> "$CSV_OUTPUT_FILE"
done
