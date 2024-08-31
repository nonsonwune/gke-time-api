# terraform/main.tf

# Configure the Google Cloud provider
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file("terraform-sa-key.json")
}

# Add the google_client_config data source
data "google_client_config" "default" {}

# VPC
resource "google_compute_network" "time_api_vpc" {
  name                    = "time-api-vpc"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "time_api_subnet" {
  name          = "time-api-subnet"
  region        = var.region
  network       = google_compute_network.time_api_vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

# NAT Router
resource "google_compute_router" "time_api_router" {
  name    = "time-api-router"
  region  = var.region
  network = google_compute_network.time_api_vpc.name
}

# NAT Gateway
resource "google_compute_router_nat" "time_api_nat" {
  name                               = "time-api-nat"
  router                             = google_compute_router.time_api_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall rule to allow internal communication
resource "google_compute_firewall" "internal" {
  name    = "time-api-allow-internal"
  network = google_compute_network.time_api_vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.10.0.0/24"]
}

# Firewall rule to allow HTTP/HTTPS traffic
resource "google_compute_firewall" "http" {
  name    = "time-api-allow-http"
  network = google_compute_network.time_api_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gke-node", "time-api-gke"]
}

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

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    machine_type = "e2-medium"
    tags         = ["gke-node", "time-api-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Updated Kubernetes provider configuration
provider "kubernetes" {
  host                   = "https://${google_container_cluster.time_api_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.time_api_cluster.master_auth[0].cluster_ca_certificate)
}

# Kubernetes Namespace
resource "kubernetes_namespace" "time_api" {
  metadata {
    name = "time-api"
  }
}

# Kubernetes Deployment
resource "kubernetes_deployment" "time_api" {
  metadata {
    name      = "time-api"
    namespace = kubernetes_namespace.time_api.metadata[0].name
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "time-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "time-api"
        }
      }

      spec {
        container {
          image = "gcr.io/${var.project_id}/time-api:latest"
          name  = "time-api"

          port {
            container_port = 8080
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

# Kubernetes Service
resource "kubernetes_service" "time_api" {
  metadata {
    name      = "time-api"
    namespace = kubernetes_namespace.time_api.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_deployment.time_api.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}
