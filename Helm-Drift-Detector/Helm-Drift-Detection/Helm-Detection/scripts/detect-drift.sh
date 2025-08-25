#!/bin/bash
# USAGE: ./detect-drift.sh desired.yaml

  DESIRED_FILE="${1:-desired.yaml}"
  HPA_NAMESPACE="sandbox-nginx"
  drift_detected=false

  echo -e "\nStarting Helm Drift Detection by Rendering $DESIRED_FILE"
  echo ""


  # HPA: Load from desired.yaml

  LOCAL_HPA_NAME=$(yq e 'select(.kind=="HorizontalPodAutoscaler") | .metadata.name' "$DESIRED_FILE")
  LOCAL_MIN_REPLICAS=$(yq e 'select(.kind=="HorizontalPodAutoscaler") | .spec.minReplicas' "$DESIRED_FILE")
  LOCAL_MAX_REPLICAS=$(yq e 'select(.kind=="HorizontalPodAutoscaler") | .spec.maxReplicas' "$DESIRED_FILE")
  LOCAL_CPU_TARGET=$(yq e 'select(.kind=="HorizontalPodAutoscaler") | .spec.metrics[] | select(.resource.name=="cpu") | .resource.target.averageUtilization' "$DESIRED_FILE")

echo -e "Local HPA:\n min=$LOCAL_MIN_REPLICAS\n max=$LOCAL_MAX_REPLICAS\n cpuTarget=$LOCAL_CPU_TARGET\n"


# SVC: Load from desired.yaml

  LOCAL_SVC_NAME=$(yq e 'select(.kind=="Service") | .metadata.name' "$DESIRED_FILE")
  LOCAL_PORT=$(yq e 'select(.kind=="Service") | .spec.ports[0].port' "$DESIRED_FILE")
  LOCAL_TARGET_PORT=$(yq e 'select(.kind=="Service") | .spec.ports[0].targetPort' "$DESIRED_FILE")

echo -e "Local Service:\n port=$LOCAL_PORT\n targetPort=$LOCAL_TARGET_PORT\n"
  echo ""


  # Get live HPA from cluster

  LIVE_HPA_JSON=$(kubectl get hpa "$LOCAL_HPA_NAME" -n "$HPA_NAMESPACE" -o json 2>/dev/null)
  if [[ -z "$LIVE_HPA_JSON" ]]; then
echo " Error: Could not retrieve HPA '$LOCAL_HPA_NAME' from cluster."
  exit 1
  fi
  LIVE_MIN_REPLICAS=$(echo "$LIVE_HPA_JSON" | yq e '.spec.minReplicas' -)
  LIVE_MAX_REPLICAS=$(echo "$LIVE_HPA_JSON" | yq e '.spec.maxReplicas' -)
  LIVE_CPU_TARGET=$(echo "$LIVE_HPA_JSON" | yq e '.spec.metrics[] | select(.resource.name=="cpu") | .resource.target.averageUtilization' -)

echo -e " Live HPA:\n min=$LIVE_MIN_REPLICAS\n max=$LIVE_MAX_REPLICAS\n cpuTarget=$LIVE_CPU_TARGET\n"


# Get live Service

  LIVE_SVC_JSON=$(kubectl get svc "$LOCAL_SVC_NAME" -n "$HPA_NAMESPACE" -o json 2>/dev/null)
  if [[ -z "$LIVE_SVC_JSON" ]]; then
echo " Error: Could not retrieve Service '$LOCAL_SVC_NAME' from cluster."
  exit 1
  fi
  LIVE_PORT=$(echo "$LIVE_SVC_JSON" | yq e '.spec.ports[0].port' -)
  LIVE_TARGET_PORT=$(echo "$LIVE_SVC_JSON" | yq e '.spec.ports[0].targetPort' -)

echo -e " Live Service:\n port=$LIVE_PORT\n targetPort=$LIVE_TARGET_PORT\n"
  echo ""


  # DRIFT REPORT

echo -e " Drift Report :\n"

  # HPA Comparisons

  if [[ "$LOCAL_MIN_REPLICAS" != "$LIVE_MIN_REPLICAS" ]]; then
echo -e " DRIFT:\n minReplicas (Local=$LOCAL_MIN_REPLICAS, Live=$LIVE_MIN_REPLICAS)\n"
  drift_detected=true
  fi

  if [[ "$LOCAL_MAX_REPLICAS" != "$LIVE_MAX_REPLICAS" ]]; then
echo -e " DRIFT:\n maxReplicas (Local=$LOCAL_MAX_REPLICAS, Live=$LIVE_MAX_REPLICAS)\n"
  drift_detected=true
  fi

  if [[ "$LOCAL_CPU_TARGET" != "$LIVE_CPU_TARGET" ]]; then
echo -e " DRIFT:\n CPU Target (Local=$LOCAL_CPU_TARGET%, Live=$LIVE_CPU_TARGET%)\n"
  drift_detected=true
  fi

  # Service Port Comparisons

  if [[ "$LOCAL_PORT" != "$LIVE_PORT" ]]; then
echo -e " DRIFT:\n Service Port (Local=$LOCAL_PORT, Live=$LIVE_PORT)\n"
  drift_detected=true
  fi

  if [[ "$LOCAL_TARGET_PORT" != "$LIVE_TARGET_PORT" ]]; then
echo -e " DRIFT:\n Service TargetPort (Local=$LOCAL_TARGET_PORT, Live=$LIVE_TARGET_PORT)\n"
  drift_detected=true
  fi


  # Final Result

  if [[ "$drift_detected" == false ]]; then
echo -e "\n SUCCESS: No drift detected."
  exit 0

  else
  echo -e " \n Drift detected. Please review the differences."
  exit 2
  fi

