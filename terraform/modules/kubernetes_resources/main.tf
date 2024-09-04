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
    replicas = 2

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
        annotations = {
          "iam.gke.io/gcp-service-account" = "gke-node-sa@time-api-gke-project-434215.iam.gserviceaccount.com"
        }
      }

      spec {
        service_account_name = "gke-node-sa"

        container {
          image = "gcr.io/${var.project_id}/time-api:${var.image_tag}"
          name  = "time-api"

          port {
            container_port = 8080
          }

          resources {
            limits = {
              cpu    = "250m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 5
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
        port     = "8080"
        protocol = "TCP"
      }
    }

    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}
