resource "kubernetes_namespace" "time_api" {
  metadata {
    name = "time-api"
  }
}

resource "kubernetes_deployment" "time_api" {
  metadata {
    name      = "time-api"
    namespace = kubernetes_namespace.time_api.metadata[0].name
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "time-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "time-api"
        }
      }

      spec {
        container {
          image = "gcr.io/${var.project_id}/time-api:${var.image_tag}"
          name  = "time-api"

          port {
            container_port = 8080
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/time"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/time"
              port = 8080
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "time_api" {
  metadata {
    name      = "time-api"
    namespace = kubernetes_namespace.time_api.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.time_api.spec[0].template[0].metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_network_policy" "default_deny_all" {
  metadata {
    name      = "default-deny-all"
    namespace = kubernetes_namespace.time_api.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy" "allow_time_api" {
  metadata {
    name      = "allow-time-api"
    namespace = kubernetes_namespace.time_api.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = "time-api"
      }
    }

    ingress {
      from {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }

      ports {
        port     = 8080
        protocol = "TCP"
      }
    }

    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }

      ports {
        port     = 443
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
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

resource "null_resource" "kubernetes_network_policy" {
  depends_on = [null_resource.check_gke_plugin]

  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.region}-a --project ${var.project_id}
      kubectl apply -f ${path.module}/network_policy.yaml --validate=false
    EOT
  }
}

resource "kubernetes_network_policy" "time_api_network_policy" {
  metadata {
    name      = "time-api-network-policy"
    namespace = "default"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "time-api"
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "default"
          }
        }
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}
