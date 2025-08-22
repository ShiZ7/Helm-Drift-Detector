#!/bin/bash

echo "Running in RAW mode (direct Kubernetes diff)"
bash ./scripts/detect-drift desired.yaml | tee drift.log
bash ./scripts/log_to_csv.sh drift.log drift_history.csv
