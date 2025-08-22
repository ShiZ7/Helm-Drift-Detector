#!/bin/bash

DRIFT_OUTPUT_FILE="${1:-drift.log}"
CSV_OUTPUT_FILE="${2:-drift_history.csv}"

# Initialize CSV if it doesn't exist

if [ ! -f "$CSV_OUTPUT_FILE" ]; then
  echo "Timestamp,Resource,Field,Local,Live" > "$CSV_OUTPUT_FILE"
fi

# Extract DRIFT lines from log and convert to CSV

grep "DRIFT:" "$DRIFT_OUTPUT_FILE" | while IFS= read -r line; do
  field=$(echo "$line" | cut -d ':' -f2 | cut -d '(' -f1 | xargs)
  values=$(echo "$line" | grep -oP '\(Local=.*?, Live=.*?\)' | sed 's/[()]//g')
  local_val=$(echo "$values" | sed -n 's/Local=\(.*\), Live=.*/\1/p')
  live_val=$(echo "$values" | sed -n 's/.*Live=\(.*\)/\1/p')
  echo "$(date),HPA/$field,$field,$local_val,$live_val" >> "$CSV_OUTPUT_FILE"
done

