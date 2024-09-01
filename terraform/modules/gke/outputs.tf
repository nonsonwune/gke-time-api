# modules/gke/outputs.tf

output "cluster_name" {
  value       = data.google_container_cluster.time_api_cluster.name
  description = "GKE Cluster Name"
}

output "cluster_endpoint" {
  value       = data.google_container_cluster.time_api_cluster.endpoint
  description = "GKE Cluster Host"
}


output "cluster_ca_certificate" {
  value       = data.google_container_cluster.time_api_cluster.master_auth[0].cluster_ca_certificate
  description = "GKE Cluster CA Certificate"
  sensitive   = true
}
