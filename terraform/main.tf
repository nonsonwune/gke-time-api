resource "google_container_cluster" "primary" {
  name     = "time-api-gke-cluster"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "time-api-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    machine_type = "n1-standard-1"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

module "networking" {
  source     = "./modules/networking"
  project_id = var.project_id
  region     = var.region
  vpc_name   = google_compute_network.vpc.name
}

module "kubernetes_resources" {
  source      = "./modules/kubernetes_resources"
  project_id  = var.project_id
  region      = var.region
  image_tag   = var.image_tag
  vpc_name    = google_compute_network.vpc.name
  subnet_name = google_compute_subnetwork.subnet.name
  depends_on  = [google_container_cluster.primary]
}

resource "google_project_service" "services" {
  for_each = toset([
    "container.googleapis.com",
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])
  project = var.project_id
  service = each.key

  disable_on_destroy = false
}

resource "null_resource" "configure_kubectl" {
  depends_on = [google_container_cluster.primary]

  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${google_container_cluster.primary.name} \
        --region ${var.region} \
        --project ${var.project_id}
    EOT
  }
}
