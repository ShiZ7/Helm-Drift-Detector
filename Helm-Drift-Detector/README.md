# Project Title: Helm-Drift-Detector

> Automated Helm Drift Detection for Kubernetes HPA and Service Ports  powered by Bash, yq, and GitHub Actions to detect changes made in live cluster before one commits again to same file as well as useful for PRs along with saving the logs of changes with timestamps, changes made and editor's name in CSV format in a single file in same github repo making it organized and accountable feature.

# Description: 

> It helps in monitoring and configuration of mismatches before they reach production.

> This project detects drift between local helm values and live kubernetes cluster configurations.

> It prevent incorrect changes from getting merged by running as a GitHub Action in every Pull Request to main or master.

# Usage:

> It ensures the following are always in sync and check if there is any drift caused between them:

  1) minReplicas, maxReplicas
  2) CPU Utilization target
  3) Service ports (port, targetPort)
     
> Drift results are logged in csv format with timestamp along with editor's name and uploaded automatically.

# Installation (For Local Setup):
Bash --> In Terminal either local or IDE.

## Clone the Repository

> CLI : gh repo clone shivansh-gupta_inmobi/Helm-Drift-Detector

> HTTPS : https://github.com/shivansh-gupta_inmobi/Helm-Drift-Detector.git

## Make Scripts Executable

> chmod +x ./scripts/*

## Running Helm Template Rendering

> helm template test-nginx ./charts/nginx -n sandbox-nginx -f ./charts/nginx/values.yaml > desired.yaml

## Run Drift Detection

> ./scripts/detect-drift desired.yaml

# Proof Of Work (In Local Terminal):

<img width="1439" height="898" alt="Screenshot 2025-08-20 at 1 02 16 PM" src="https://github.com/user-attachments/assets/fa85eca5-abfd-4135-9253-9c93ad489a8d" />


# Contributing:

> To improve the drift detection logic or support:

  1) Create a Feature Branch
  2) Open a Pull Request
     
> Please ensure the changes you made are well tested before submitting.

# License:

>MIT License © 2025 Shivansh Gupta
Feel free to use, modify, and distribute with attribution.
