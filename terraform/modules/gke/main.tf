# modules/gke/main.tf

resource "google_container_cluster" "time_api_cluster" {
  name     = "time-api-gke-cluster"
  location = "${var.region}-a"
  project  = var.project_id

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.vpc_name
  subnetwork = var.subnet_name

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-time-api-gke-cluster-pods-6a4f6ce0"
    services_secondary_range_name = "gke-time-api-gke-cluster-services"
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
