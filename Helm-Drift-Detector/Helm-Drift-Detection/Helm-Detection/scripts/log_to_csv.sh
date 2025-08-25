#!/bin/bash

DRIFT_OUTPUT_FILE="${1:-drift.log}"
CSV_OUTPUT_FILE="${2:-drift_history.csv}"

# Initialize CSV if it doesn't exist
if [ ! -f "$CSV_OUTPUT_FILE" ]; then
  echo "timestamp,namespace,resource_type,resource_name,field,declared,observed,editor" > "$CSV_OUTPUT_FILE"
fi

# Extract DRIFT lines from log and convert to CSV
grep "DRIFT:" "$DRIFT_OUTPUT_FILE" | while IFS= read -r line; do
  timestamp=$(date --utc +"%Y-%m-%dT%H:%M:%SZ")
  namespace="sandbox-nginx"  # Default, change as needed
  resource_type="HPA"  # Default, adjust per drift detection type
  resource_name="test-nginx"  # Example, change according to your detection output
  field=$(echo "$line" | cut -d ':' -f2 | cut -d '(' -f1 | xargs)
  values=$(echo "$line" | grep -oP '(Local=\s*[^,]+, Live=\s*[^)]+)' | sed "s/\(Local=\|, Live=\)//g")
  
  declared=$(echo "$values" | cut -d ' ' -f1)
  observed=$(echo "$values" | cut -d ' ' -f2)
  editor="ShiZ7"  # Adjust if needed, or extract dynamically if possible

  echo "$timestamp,$namespace,$resource_type,$resource_name,$field,$declared,$observed,$editor" >> "$CSV_OUTPUT_FILE"
done

