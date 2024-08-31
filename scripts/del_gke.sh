#!/bin/bash

# Set your project ID and cluster details
PROJECT_ID="time-api-gke-project-434215"
CLUSTER_NAME="time-api-gke-cluster"
ZONE="us-central1-a"

# Delete the existing cluster
gcloud container clusters delete $CLUSTER_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --quiet

echo "Cluster $CLUSTER_NAME has been deleted. You can now recreate it using Terraform."