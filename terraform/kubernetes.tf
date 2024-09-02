resource "null_resource" "kubernetes_config" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${module.gke.cluster_name} --zone ${var.zone} --project ${var.project_id}
    EOT
  }

  depends_on = [module.gke]
}

resource "null_resource" "debug_info" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Project ID: ${var.project_id}"
      echo "Zone: ${var.zone}"
      echo "GKE Cluster Name: ${module.gke.cluster_name}"
      echo "GKE Cluster Endpoint: ${module.gke.cluster_endpoint}"
      echo "Kubernetes Host: https://${module.gke.cluster_endpoint}"
      echo "Cluster CA Certificate: ${module.gke.cluster_ca_certificate}"
    EOT
  }

  depends_on = [module.gke, module.kubernetes_resources, null_resource.kubernetes_config]
}
