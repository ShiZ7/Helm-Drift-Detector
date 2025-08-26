#!/bin/bash
# USAGE: ./generate-report.sh <input-log-file> <output-csv-file> <pr-author> <pr-number> <namespace>
# This script parses the output of the drift detection script and appends drift events to a CSV file.

set -euo pipefail

# --- Arguments ---
INPUT_LOG_FILE="$1"
OUTPUT_CSV_FILE="$2"
PR_AUTHOR="$3"
PR_NUMBER="$4"
NAMESPACE="$5"

# --- CSV Header ---
if [ ! -f "$OUTPUT_CSV_FILE" ]; then
  echo "Timestamp,Editor,PR_Number,Namespace,Resource,Field,Local_Value,Live_Value" > "$OUTPUT_CSV_FILE"
fi

# Get current timestamp in ISO 8601 format
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- MODIFICATION START ---
# This method is more robust and avoids subshell issues that can cause writes to fail.
# It reads from the output of the grep command line-by-line.
drift_found=false
while IFS=':' read -r _ resource field local_val live_val; do
    # Append a new row to the CSV file for each line of drift data found
    echo "$TIMESTAMP,$PR_AUTHOR,$PR_NUMBER,$NAMESPACE,$resource,$field,$local_val,$live_val" >> "$OUTPUT_CSV_FILE"
    drift_found=true
done < <(grep "DRIFT_DATA:" "$INPUT_LOG_FILE" || true) # The '|| true' ensures the script doesn't fail if no drift is found

if [ "$drift_found" = true ]; then
    echo "Drift report successfully updated at $OUTPUT_CSV_FILE"
else
    echo "No drift data found in log file to report. Skipping CSV update."
fi
# --- MODIFICATION END ---
