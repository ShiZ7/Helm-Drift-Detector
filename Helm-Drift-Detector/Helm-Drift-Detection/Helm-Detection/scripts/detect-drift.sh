#!/bin/bash
# USAGE: ./detect-drift.sh <desired-yaml-file>
# This script compares a desired state YAML with the live state in Kubernetes
# and exits with status 2 if any drift is detected.
# It also outputs structured data for logging purposes.

set -euo pipefail

# --- Configuration ---
DESIRED_FILE="${1:-desired.yaml}"
NAMESPACE="sandbox-nginx" # Made this a variable at the top for clarity
drift_detected=false

echo -e "\nStarting Helm Drift Detection for namespace '$NAMESPACE' using '$DESIRED_FILE'"
echo "------------------------------------------------------------------"

# --- Helper function for logging drift ---
log_drift() {
  local resource="$1"
  local field="$2"
  local local_val="$3"
  local live_val="$4"
  # Human-readable output
  echo -e "DRIFT: $resource -> $field (Local=$local_val, Live=$live_val)"
  # Machine-readable output for the report generator
  echo "DRIFT_DATA:$resource:$field:$local_val:$live_val"
  drift_detected=true
}


# --- HPA: Load from desired.yaml ---
LOCAL_HPA_NAME=$(yq e 'select(.kind=="HorizontalPodAutoscaler") | .metadata.name' "$DESIRED_FILE")
LOCAL_MIN_REPLICAS=$(yq e 'select(.kind=="HorizontalPodAutoscaler") | .spec.minReplicas' "$DESIRED_FILE")
LOCAL_MAX_REPLICAS=$(yq e 'select(.kind=="HorizontalPodAutoscaler") | .spec.maxReplicas' "$DESIRED_FILE")
LOCAL_CPU_TARGET=$(yq e 'select(.kind=="HorizontalPodAutoscaler") | .spec.metrics[] | select(.resource.name=="cpu") | .resource.target.averageUtilization' "$DESIRED_FILE")
echo -e "Local HPA '$LOCAL_HPA_NAME':\n  minReplicas: $LOCAL_MIN_REPLICAS\n  maxReplicas: $LOCAL_MAX_REPLICAS\n  cpuTarget: $LOCAL_CPU_TARGET\n"


# --- SVC: Load from desired.yaml ---
LOCAL_SVC_NAME=$(yq e 'select(.kind=="Service") | .metadata.name' "$DESIRED_FILE")
LOCAL_PORT=$(yq e 'select(.kind=="Service") | .spec.ports[0].port' "$DESIRED_FILE")
LOCAL_TARGET_PORT=$(yq e 'select(.kind=="Service") | .spec.ports[0].targetPort' "$DESIRED_FILE")
echo -e "Local Service '$LOCAL_SVC_NAME':\n  port: $LOCAL_PORT\n  targetPort: $LOCAL_TARGET_PORT\n"


# --- Get live HPA from cluster ---
LIVE_HPA_JSON=$(kubectl get hpa "$LOCAL_HPA_NAME" -n "$NAMESPACE" -o json 2>/dev/null)
if [[ -z "$LIVE_HPA_JSON" ]]; then
  echo "Error: Could not retrieve HPA '$LOCAL_HPA_NAME' from namespace '$NAMESPACE'."
  exit 1
fi
LIVE_MIN_REPLICAS=$(echo "$LIVE_HPA_JSON" | yq e '.spec.minReplicas' -)
LIVE_MAX_REPLICAS=$(echo "$LIVE_HPA_JSON" | yq e '.spec.maxReplicas' -)
LIVE_CPU_TARGET=$(echo "$LIVE_HPA_JSON" | yq e '.spec.metrics[] | select(.resource.name=="cpu") | .resource.target.averageUtilization' -)
echo -e "Live HPA '$LOCAL_HPA_NAME':\n  minReplicas: $LIVE_MIN_REPLICAS\n  maxReplicas: $LIVE_MAX_REPLICAS\n  cpuTarget: $LIVE_CPU_TARGET\n"


# --- Get live Service from cluster ---
LIVE_SVC_JSON=$(kubectl get svc "$LOCAL_SVC_NAME" -n "$NAMESPACE" -o json 2>/dev/null)
if [[ -z "$LIVE_SVC_JSON" ]]; then
  echo "Error: Could not retrieve Service '$LOCAL_SVC_NAME' from namespace '$NAMESPACE'."
  exit 1
fi
LIVE_PORT=$(echo "$LIVE_SVC_JSON" | yq e '.spec.ports[0].port' -)
LIVE_TARGET_PORT=$(echo "$LIVE_SVC_JSON" | yq e '.spec.ports[0].targetPort' -)
echo -e "Live Service '$LOCAL_SVC_NAME':\n  port: $LIVE_PORT\n  targetPort: $LIVE_TARGET_PORT\n"


# --- Drift Report ---
echo "------------------------------------------------------------------"
echo -e "Drift Report:"
echo "------------------------------------------------------------------"

# HPA Comparisons
if [[ "$LOCAL_MIN_REPLICAS" != "$LIVE_MIN_REPLICAS" ]]; then
  log_drift "HPA/$LOCAL_HPA_NAME" "minReplicas" "$LOCAL_MIN_REPLICAS" "$LIVE_MIN_REPLICAS"
fi
if [[ "$LOCAL_MAX_REPLICAS" != "$LIVE_MAX_REPLICAS" ]]; then
  log_drift "HPA/$LOCAL_HPA_NAME" "maxReplicas" "$LOCAL_MAX_REPLICAS" "$LIVE_MAX_REPLICAS"
fi
if [[ "$LOCAL_CPU_TARGET" != "$LIVE_CPU_TARGET" ]]; then
  log_drift "HPA/$LOCAL_HPA_NAME" "cpuTarget" "$LOCAL_CPU_TARGET" "$LIVE_CPU_TARGET"
fi

# Service Port Comparisons
if [[ "$LOCAL_PORT" != "$LIVE_PORT" ]]; then
  log_drift "Service/$LOCAL_SVC_NAME" "port" "$LOCAL_PORT" "$LIVE_PORT"
fi
if [[ "$LOCAL_TARGET_PORT" != "$LIVE_TARGET_PORT" ]]; then
  log_drift "Service/$LOCAL_SVC_NAME" "targetPort" "$LOCAL_TARGET_PORT" "$LIVE_TARGET_PORT"
fi


# --- Final Result ---
if [[ "$drift_detected" == false ]]; then
  echo -e "\nSUCCESS: No drift detected."
  exit 0
else
  echo -e "\nFAILURE: Drift detected. Please review the differences."
  exit 2 # Use a specific exit code for drift
fi
