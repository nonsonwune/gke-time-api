data "google_service_account" "existing_gke_node_sa" {
  account_id = "gke-node-sa"
  project    = var.project_id
}

resource "google_service_account" "gke_node_sa" {
  count        = data.google_service_account.existing_gke_node_sa.email == null ? 1 : 0
  account_id   = "gke-node-sa"
  display_name = "GKE Node Service Account"
  project      = var.project_id
}

locals {
  gke_node_sa_email = coalesce(
    data.google_service_account.existing_gke_node_sa.email,
    try(google_service_account.gke_node_sa[0].email, "")
  )
}

resource "google_project_iam_member" "gke_node_sa_storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${local.gke_node_sa_email}"
}

resource "google_project_iam_member" "gke_node_sa_monitoring_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${local.gke_node_sa_email}"
}

resource "google_project_iam_member" "gke_node_sa_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${local.gke_node_sa_email}"
}
