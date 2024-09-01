resource "null_resource" "kubernetes_config" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${var.zone} --project ${var.project_id}
      kubectl get nodes
    EOT
  }

  depends_on = [google_container_cluster.primary]
}

resource "null_resource" "debug_info" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Debug information:"
      echo "GKE Cluster Endpoint: ${google_container_cluster.primary.endpoint}"
      echo "Kubernetes Host: https://${google_container_cluster.primary.endpoint}"
      echo "Current kubeconfig:"
      kubectl config view
      echo "Current GCP configuration:"
      gcloud config list
    EOT
  }

  depends_on = [google_container_cluster.primary, module.kubernetes_resources, null_resource.kubernetes_config]
}
