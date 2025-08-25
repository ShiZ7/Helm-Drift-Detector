#!/usr/bin/env bash
set -euo pipefail
NS="${NAMESPACE:-sandbox-nginx}"
HPA="${HPA_NAME:-test-nginx}"
NEW_MIN="${NEW_MIN:-4}"
kubectl patch hpa "$HPA" -n "$NS" --type merge -p "{\"spec\":{\"minReplicas\":$NEW_MIN}}"
echo -n "Live minReplicas now: "
kubectl get hpa "$HPA" -n "$NS" -o jsonpath='{.spec.minReplicas}'; echo
