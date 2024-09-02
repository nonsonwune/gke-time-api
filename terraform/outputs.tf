output "kubernetes_cluster_name" {
  value       = module.gke.cluster_name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = module.gke.cluster_endpoint
  description = "GKE Cluster Host"
}

output "kubectl_command" {
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --zone ${var.zone} --project ${var.project_id}"
  description = "kubectl command to connect to the cluster"
}
