resource "google_container_cluster" "primary" {
  name     = "time-api-gke-cluster"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = module.networking.vpc_name
  subnetwork = module.networking.subnet_name
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "time-api-node-pool"
  location   = var.zone
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

    machine_type = "e2-standard-2"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

module "networking" {
  source     = "./modules/networking"
  project_id = var.project_id
  zone       = var.zone
  vpc_name   = "${var.project_id}-vpc"
}

module "kubernetes_resources" {
  source           = "./modules/kubernetes_resources"
  project_id       = var.project_id
  zone             = var.zone
  image_tag        = var.image_tag
  vpc_name         = module.networking.vpc_name
  subnet_name      = module.networking.subnet_name
  cluster_endpoint = google_container_cluster.primary.endpoint
  depends_on       = [google_container_cluster.primary, google_container_node_pool.primary_nodes]
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

resource "null_resource" "kubectl_config" {
  depends_on = [google_container_cluster.primary, google_container_node_pool.primary_nodes]

  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${google_container_cluster.primary.name} \
        --zone ${var.zone} \
        --project ${var.project_id}
      kubectl cluster-info
    EOT
  }
}
