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
# First, check if the log file contains any drift data using grep -q (quiet mode).
# This prevents the script from failing if no drift is found.
if grep -q "DRIFT_DATA:" "$INPUT_LOG_FILE"; then
  echo "Drift data found. Generating report..."
  
  # If drift exists, process the lines and append to the CSV.
  # This pipe is now safe because we know grep will find matches and exit with 0.
  grep "DRIFT_DATA:" "$INPUT_LOG_FILE" | while IFS=':' read -r _ resource field local_val live_val; do
      # Append a new row to the CSV file
      echo "$TIMESTAMP,$PR_AUTHOR,$PR_NUMBER,$NAMESPACE,$resource,$field,$local_val,$live_val" >> "$OUTPUT_CSV_FILE"
  done

  echo "Drift report successfully updated at $OUTPUT_CSV_FILE"
else
  # If no drift is found, print a message and exit successfully.
  echo "No drift data found in log file to report. Skipping CSV update."
fi
# --- MODIFICATION END ---
