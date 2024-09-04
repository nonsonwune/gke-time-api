#!/bin/bash

# Get the current PROJECT_ID
PROJECT_ID=$(gcloud config get-value project)

# Get the current Git commit SHA
GITHUB_SHA=$(git rev-parse HEAD)

# Replace placeholders and apply the configuration
sed -e "s/\$(PROJECT_ID)/$PROJECT_ID/g" \
    -e "s/\$(GITHUB_SHA)/$GITHUB_SHA/g" \
    terraform/modules/kubernetes_resources/k8s-resources.yaml | kubectl apply -f -