resource "kubernetes_namespace" "time_api" {
  metadata {
    name = "time-api"
  }
  depends_on = [var.cluster_endpoint]
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
  depends_on = [kubernetes_namespace.time_api]
}

resource "kubernetes_service" "time_api" {
  metadata {
    name      = "time-api"
    namespace = kubernetes_namespace.time_api.metadata[0].name
  }

  spec {
    selector = {
      app = "time-api"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
  depends_on = [kubernetes_deployment.time_api]
}

resource "kubernetes_network_policy" "time_api" {
  metadata {
    name      = "time-api-network-policy"
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
    }

    egress {}

    policy_types = ["Ingress", "Egress"]
  }

  depends_on = [kubernetes_namespace.time_api]
}
