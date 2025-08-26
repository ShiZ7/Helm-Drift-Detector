#!/bin/bash
# USAGE: ./detect-drift.sh desired.yaml

  DESIRED_FILE="${1:-desired.yaml}"
  HPA_NAMESPACE="sandbox-nginx"
  drift_detected=false

  echo -e "\nStarting Helm Drift Detection by Rendering $DESIRED_FILE"
  echo ""


  # HPA: Load from desired.yaml

  PR_HPA_NAME=$(yq e 'select(.kind=="HorizontalPodAutoscaler") | .metadata.name' "$DESIRED_FILE")
  PR_MIN_REPLICAS=$(yq e 'select(.kind=="HorizontalPodAutoscaler") | .spec.minReplicas' "$DESIRED_FILE")
  PR_MAX_REPLICAS=$(yq e 'select(.kind=="HorizontalPodAutoscaler") | .spec.maxReplicas' "$DESIRED_FILE")
  PR_CPU_TARGET=$(yq e 'select(.kind=="HorizontalPodAutoscaler") | .spec.metrics[] | select(.resource.name=="cpu") | .resource.target.averageUtilization' "$DESIRED_FILE")

echo -e "PR HPA:\n min=$PR_MIN_REPLICAS\n max=$PR_MAX_REPLICAS\n cpuTarget=$PR_CPU_TARGET\n"


# SVC: Load from desired.yaml

  PR_SVC_NAME=$(yq e 'select(.kind=="Service") | .metadata.name' "$DESIRED_FILE")
  PR_PORT=$(yq e 'select(.kind=="Service") | .spec.ports[0].port' "$DESIRED_FILE")
  PR_TARGET_PORT=$(yq e 'select(.kind=="Service") | .spec.ports[0].targetPort' "$DESIRED_FILE")

echo -e "Local Service:\n port=$PR_PORT\n targetPort=$PR_TARGET_PORT\n"
  echo ""


  # Get live HPA from cluster

  Cluster_HPA_JSON=$(kubectl get hpa "$PR_HPA_NAME" -n "$HPA_NAMESPACE" -o json 2>/dev/null)
  if [[ -z "$Cluster_HPA_JSON" ]]; then
echo " Error: Could not retrieve HPA '$PR_HPA_NAME' from cluster."
  exit 1
  fi
  Cluster_MIN_REPLICAS=$(echo "$PR_HPA_JSON" | yq e '.spec.minReplicas' -)
  Cluster_MAX_REPLICAS=$(echo "$PR_HPA_JSON" | yq e '.spec.maxReplicas' -)
  Cluster_CPU_TARGET=$(echo "$PR_HPA_JSON" | yq e '.spec.metrics[] | select(.resource.name=="cpu") | .resource.target.averageUtilization' -)

echo -e " Cluster HPA:\n min=$Cluster_MIN_REPLICAS\n max=$Cluster_MAX_REPLICAS\n cpuTarget=$Cluster_CPU_TARGET\n"


# Get live Service

  Cluster_SVC_JSON=$(kubectl get svc "$PR_SVC_NAME" -n "$HPA_NAMESPACE" -o json 2>/dev/null)
  if [[ -z "$Cluster_SVC_JSON" ]]; then
echo " Error: Could not retrieve Service '$PR_SVC_NAME' from cluster."
  exit 1
  fi
  Cluster_PORT=$(echo "$Cluster_SVC_JSON" | yq e '.spec.ports[0].port' -)
  Cluster_TARGET_PORT=$(echo "$Cluster_SVC_JSON" | yq e '.spec.ports[0].targetPort' -)

echo -e " Cluster Service:\n port=$Cluster_PORT\n targetPort=$Cluster_TARGET_PORT\n"
  echo ""


  # DRIFT REPORT

echo -e " Drift Report :\n"

  # HPA Comparisons

  if [[ "$LPR_MIN_REPLICAS" != "$Cluster_MIN_REPLICAS" ]]; then
echo -e " DRIFT:\n minReplicas (Local=$LOCAL_MIN_REPLICAS, Live=$LIVE_MIN_REPLICAS)\n"
  drift_detected=true
  fi

  if [[ "$PR_MAX_REPLICAS" != "$Cluster_MAX_REPLICAS" ]]; then
echo -e " DRIFT:\n maxReplicas (Local=$LOCAL_MAX_REPLICAS, Live=$LIVE_MAX_REPLICAS)\n"
  drift_detected=true
  fi

  if [[ "$PR_CPU_TARGET" != "$Cluster_CPU_TARGET" ]]; then
echo -e " DRIFT:\n CPU Target (Local=$LOCAL_CPU_TARGET%, Live=$LIVE_CPU_TARGET%)\n"
  drift_detected=true
  fi

  # Service Port Comparisons

  if [[ "$PR_PORT" != "$Cluster_PORT" ]]; then
echo -e " DRIFT:\n Service Port (Local=$LOCAL_PORT, Live=$LIVE_PORT)\n"
  drift_detected=true
  fi

  if [[ "$PR_TARGET_PORT" != "$Cluster_TARGET_PORT" ]]; then
echo -e " DRIFT:\n Service TargetPort (PR=$PR_TARGET_PORT, Cluster=$Cluster_TARGET_PORT)\n"
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
