#!/bin/bash

# Render Helm chart and save to desired.yaml
helm template test-nginx ./charts/nginx > desired.yaml

echo "Helm template rendered → desired.yaml"
bash ./scripts/detect-drift desired.yaml | tee drift.log
bash ./scripts/log_to_csv.sh drift.log drift_history.csv
