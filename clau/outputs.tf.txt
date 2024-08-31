# terraform/outputs.tf

output "kubernetes_cluster_name" {
  value       = google_container_cluster.time_api_cluster.name
  description = "GKE Cluster Name"
}

output "region" {
  value       = var.region
  description = "GCP Region"
}
