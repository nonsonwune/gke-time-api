# modules/kubernetes_resources/main.tf

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

data "google_container_cluster" "gke_cluster" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id
}

resource "kubernetes_namespace" "time_api" {
  metadata {
    name = "time-api"
  }
}

resource "kubectl_manifest" "time_api_resources" {
  yaml_body = templatefile("${path.module}/k8s-resources.yaml", {
    image_tag  = var.image_tag
    project_id = var.project_id
  })
  depends_on = [kubernetes_namespace.time_api]
}

resource "kubectl_manifest" "network_policy" {
  yaml_body  = file("${path.module}/network_policy.yaml")
  depends_on = [kubernetes_namespace.time_api]
}

resource "null_resource" "kubernetes_resources" {
  depends_on = [kubectl_manifest.time_api_resources]

  provisioner "local-exec" {
    command = <<-EOT
      if ! command -v gke-gcloud-auth-plugin >/dev/null 2>&1; then
        echo "Error: gke-gcloud-auth-plugin not found. Please install it before applying Terraform."
        exit 1
      fi
    EOT
  }
}
