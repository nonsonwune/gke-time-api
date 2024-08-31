#!/bin/bash

# Set your project ID
PROJECT_ID="time-api-gke-project-434215"

# Enable the Kubernetes Engine API
gcloud services enable container.googleapis.com --project=$PROJECT_ID

# Enable the Identity and Access Management (IAM) API
gcloud services enable iam.googleapis.com --project=$PROJECT_ID

# Enable the Compute Engine API (required for firewalls and security policies)
gcloud services enable compute.googleapis.com --project=$PROJECT_ID

# Enable the Cloud Resource Manager API (often required for project-level operations)
gcloud services enable cloudresourcemanager.googleapis.com --project=$PROJECT_ID

echo "APIs have been enabled. Please wait a few minutes for the changes to propagate before running Terraform again."