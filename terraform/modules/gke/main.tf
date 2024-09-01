resource "google_service_account" "gke_sa" {
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
}

resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_container_cluster" "time_api_cluster" {
  name     = "time-api-gke-cluster"
  location = "${var.region}-a"

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.vpc_name
  subnetwork = var.subnet_name

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  network_policy {
    enabled = true
  }

  enable_intranode_visibility = true

  # Add this block to ensure master_auth is available
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "time_api_nodes" {
  name       = "time-api-node-pool"
  location   = "${var.region}-a"
  cluster    = google_container_cluster.time_api_cluster.name
  node_count = var.gke_num_nodes

  node_config {
    service_account = google_service_account.gke_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
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
}

resource "google_compute_security_policy" "policy" {
  name = "time-api-security-policy"

  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule, higher priority overrides it"
  }

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["0.0.0.0/0"]
      }
    }
    description = "Allow all traffic"
  }
}

output "cluster_name" {
  value = google_container_cluster.time_api_cluster.name
}

output "cluster_endpoint" {
  value = google_container_cluster.time_api_cluster.endpoint
}

output "cluster_location" {
  value = google_container_cluster.time_api_cluster.location
}

output "cluster_ca_certificate" {
  value     = google_container_cluster.time_api_cluster.master_auth[0].cluster_ca_certificate
  sensitive = true
}
