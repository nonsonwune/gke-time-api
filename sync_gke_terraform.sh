#!/bin/bash

# Set project ID and cluster name
PROJECT_ID="time-api-gke-project-434215"
CLUSTER_NAME="time-api-gke-cluster"
ZONE="us-central1-a"

# Get the list of node pools
NODE_POOLS=$(gcloud container node-pools list --cluster=$CLUSTER_NAME --zone=$ZONE --format="value(name)")

# Loop through each node pool and import it into Terraform state
for POOL in $NODE_POOLS
do
  echo "Importing node pool: $POOL"
  terraform import module.gke.google_container_node_pool.assignment_nodes projects/$PROJECT_ID/locations/$ZONE/clusters/$CLUSTER_NAME/nodePools/$POOL
done

echo "Node pools imported. Running terraform plan..."
terraform plan

echo "Review the plan above. If it looks good, run 'terraform apply' to apply the changes."