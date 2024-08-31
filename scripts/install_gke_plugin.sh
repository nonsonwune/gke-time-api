#!/bin/bash

# install_gke_plugin.sh
echo "Checking for gke-gcloud-auth-plugin..."
if ! command -v gke-gcloud-auth-plugin &> /dev/null; then
    echo "gke-gcloud-auth-plugin not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
else
    echo "gke-gcloud-auth-plugin is already installed."
fi

echo "Configuring kubectl to use gke-gcloud-auth-plugin..."
gcloud container clusters get-credentials time-api-gke-cluster --zone us-central1-a --project time-api-gke-project-434215