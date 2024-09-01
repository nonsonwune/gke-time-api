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
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
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

resource "google_monitoring_dashboard" "cluster_dashboard" {
  dashboard_json = jsonencode({
    displayName = "GKE Cluster Dashboard"
    gridLayout = {
      columns = "2"
      widgets = [
        {
          title = "CPU Usage"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"kubernetes.io/container/cpu/core_usage_time\" resource.type=\"k8s_container\""
                }
              }
            }]
          }
        },
        {
          title = "Memory Usage"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"kubernetes.io/container/memory/used_bytes\" resource.type=\"k8s_container\""
                }
              }
            }]
          }
        }
      ]
    }
  })
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
