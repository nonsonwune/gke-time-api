# modules/gke/outputs.tf

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
