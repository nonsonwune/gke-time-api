# terraform/outputs.tf

output "kubernetes_cluster_name" {
  value       = google_container_cluster.time_api_cluster.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.time_api_cluster.endpoint
  description = "GKE Cluster Host"
}

output "kubectl_command" {
  value       = "gcloud container clusters get-credentials ${google_container_cluster.time_api_cluster.name} --zone ${google_container_cluster.time_api_cluster.location} --project ${var.project_id}"
  description = "kubectl command to connect to the cluster"
}
