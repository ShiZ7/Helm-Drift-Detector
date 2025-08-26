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

# --- Parse log and append to CSV ---
# Get current timestamp in ISO 8601 format
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

drift_found=0
# Read the log file and look for our structured DRIFT_DATA lines
grep "DRIFT_DATA:" "$INPUT_LOG_FILE" | while IFS=':' read -r _ resource field local_val live_val; do
    # Append a new row to the CSV file
    echo "$TIMESTAMP,$PR_AUTHOR,$PR_NUMBER,$NAMESPACE,$resource,$field,$local_val,$live_val" >> "$OUTPUT_CSV_FILE"
    drift_found=1
done

if [ "$drift_found" -eq 1 ]; then
    echo "Drift report generated at $OUTPUT_CSV_FILE"
else
    echo "No drift data found in log file to report."
fi
