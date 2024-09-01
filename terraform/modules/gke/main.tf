resource "google_container_cluster" "time_api_cluster" {
  name     = "time-api-gke-cluster"
  location = "${var.region}-a"
  project  = var.project_id

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.vpc_name
  subnetwork = var.subnet_name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }

  addons_config {
    dns_cache_config {
      enabled = true
    }
  }
}

resource "google_container_node_pool" "time_api_nodes" {
  name       = "time-api-node-pool"
  location   = "${var.region}-a"
  cluster    = google_container_cluster.time_api_cluster.name
  node_count = var.gke_num_nodes

  node_config {
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
  name    = "time-api-security-policy"
  project = var.project_id

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
