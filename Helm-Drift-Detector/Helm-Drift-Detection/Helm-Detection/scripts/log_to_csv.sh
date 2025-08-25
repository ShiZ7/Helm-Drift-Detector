#!/bin/bash

DRIFT_OUTPUT_FILE="${1:-drift.log}"
CSV_OUTPUT_FILE="${2:-drift_report_history.csv}"

# Initialize CSV if it doesn't exist
if [ ! -f "$CSV_OUTPUT_FILE" ]; then
    echo "timestamp,namespace,resource_type,resource_name,field,declared,observed,editor" > "$CSV_OUTPUT_FILE"
fi

# Extract DRIFT lines from log and convert to CSV
grep "DRIFT:" "$DRIFT_OUTPUT_FILE" | while IFS= read -r line; do 
  timestamp=$(date +"%Y-%m-%dT%H:%M:%SZ")
  
  # Extract relevant fields from the drift log line
  field=$(echo "$line" | cut -d ':' -f2 | cut -d '(' -f1 | xargs)
  values=$(echo "$line" | grep -oP '(Local=.*?, Live=.*?\\)' | sed "s/()//g")
  
  local_val=$(echo "$values" | sed -n 's/Local=\(.*\), Live=.*/\1/p')
  live_val=$(echo "$values" | sed -n 's/.*Live=\(.*\)/\1/p')
  
  # You can modify resource type, resource name, and other values as per your needs
  resource_type="HPA"
  resource_name="test-nginx"
  declared="6"  # Example, adjust as needed
  observed="5"  # Example, adjust as needed
  editor="ShiZ7" # This should be dynamically set based on who is committing or modifying
  
  # Write to CSV file
  echo "$timestamp,sandbox-nginx,$resource_type,$resource_name,$field,$declared,$observed,$editor" >> "$CSV_OUTPUT_FILE"
done
