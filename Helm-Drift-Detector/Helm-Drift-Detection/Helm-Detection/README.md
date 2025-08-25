Detects Kubernetes HPA drift between **desired** (Git) and **live** (cluster).

Supports:
- **RAW YAML**: `manifests/desired-hpa.yaml`
- **HELM**: render HPA from `charts/<chart>` + `values/desired.yaml`

## Quick start
```bash


# RAW mode
Bash Detect-Drift \
  --namespace sandbox-nginx \
  --hpa-name test-nginx \
  --mode raw \
  --desired-file ./manifests/desired-hpa.yaml

# HELM mode
Bash Detect-Drift \
  --namespace sandbox-nginx \
  --hpa-name test-nginx \
  --mode helm \
  --release-name test-nginx \
  --chart-path ./charts/nginx \
  --values-file ./values/desired.yaml \
  --hpa-template-path templates/hpa.yaml
