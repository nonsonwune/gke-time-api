terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

resource "kubernetes_namespace" "time_api" {
  metadata {
    name = "time-api"
  }
}

resource "kubectl_manifest" "time_api_resources" {
  yaml_body  = file("${path.module}/k8s-resources.yaml")
  depends_on = [kubernetes_namespace.time_api]
}

resource "kubectl_manifest" "network_policy" {
  yaml_body  = file("${path.module}/network_policy.yaml")
  depends_on = [kubernetes_namespace.time_api]
}

resource "null_resource" "check_gke_plugin" {
  provisioner "local-exec" {
    command = <<EOT
      if ! command -v gke-gcloud-auth-plugin &> /dev/null; then
        echo "Error: gke-gcloud-auth-plugin not found. Please run ./install_gke_plugin.sh before applying Terraform."
        exit 1
      fi
    EOT
  }
}

resource "null_resource" "kubernetes_resources" {
  depends_on = [null_resource.check_gke_plugin, kubectl_manifest.time_api_resources]

  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.region}-a --project ${var.project_id}
      kubectl apply -f ${path.module}/k8s-resources.yaml
    EOT
  }
}
