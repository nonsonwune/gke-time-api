# kubernetes_provider.tf

# Kubernetes provider configuration
provider "kubernetes" {
  config_path    = "${path.module}/kubeconfig"
  config_context = "gke_${var.project_id}_${google_container_cluster.time_api_cluster.location}_${google_container_cluster.time_api_cluster.name}"
}

# Terraform data resource to ensure Kubernetes provider is configured after kubeconfig is ready
resource "terraform_data" "kubernetes_provider_ready" {
  depends_on = [terraform_data.kubeconfig_ready]
}
