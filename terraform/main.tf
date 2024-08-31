# main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Configure the Google Cloud provider
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file("terraform-sa-key.json")
}

# Add the google_client_config data source
data "google_client_config" "default" {}

# GKE cluster
resource "google_container_cluster" "time_api_cluster" {
  name     = "time-api-gke-cluster"
  location = "${var.region}-a"

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.time_api_vpc.name
  subnetwork = google_compute_subnetwork.time_api_subnet.name

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  network_policy {
    enabled = true
  }

  enable_intranode_visibility = true
}

# Separately Managed Node Pool
resource "google_container_node_pool" "time_api_nodes" {
  name       = "time-api-node-pool"
  location   = "${var.region}-a"
  cluster    = google_container_cluster.time_api_cluster.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = "time-api-production"
    }

    machine_type = "e2-standard-2"
    tags         = ["gke-node", "time-api-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  depends_on = [
    google_container_cluster.time_api_cluster
  ]
}

# Data source to fetch GKE cluster info
data "google_container_cluster" "time_api_cluster" {
  name     = google_container_cluster.time_api_cluster.name
  location = google_container_cluster.time_api_cluster.location

  depends_on = [
    google_container_cluster.time_api_cluster,
    google_container_node_pool.time_api_nodes
  ]
}

# Null resource to get GKE credentials and test connection
resource "null_resource" "get_gke_credentials" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${google_container_cluster.time_api_cluster.name} --zone ${google_container_cluster.time_api_cluster.location} --project ${var.project_id}
      kubectl config view --raw > ${path.module}/kubeconfig
      kubectl get nodes
      echo ${path.module}/kubeconfig
    EOT
  }

  depends_on = [
    google_container_cluster.time_api_cluster,
    google_container_node_pool.time_api_nodes
  ]
}

# Null resource to apply network policy
resource "null_resource" "apply_network_policy" {
  provisioner "local-exec" {
    command = "kubectl apply -f network_policy.yaml"
  }

  depends_on = [
    null_resource.get_gke_credentials
  ]
}

# Terraform data resource to signal when kubeconfig is ready
resource "terraform_data" "kubeconfig_ready" {
  input = null_resource.get_gke_credentials.id
}
