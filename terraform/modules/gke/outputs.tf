output "cluster_endpoint" {
  value       = google_container_cluster.time_api_cluster.endpoint
  description = "The IP address of the cluster master."
}

output "cluster_ca_certificate" {
  value       = google_container_cluster.time_api_cluster.master_auth[0].cluster_ca_certificate
  description = "The public certificate that is the root of trust for the cluster."
}

output "cluster_name" {
  value       = google_container_cluster.time_api_cluster.name
  description = "The name of the cluster."
}
