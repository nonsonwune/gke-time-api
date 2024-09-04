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
        image_pull_secrets {
          name = "gcr-json-key"
        }

        container {
          image             = "gcr.io/${var.project_id}/time-api:${var.image_tag}"
          name              = "time-api"
          image_pull_policy = "Always"

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

  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].image,
    ]
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
    annotations = {
      "description" = "Default deny all ingress and egress traffic"
    }
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
    annotations = {
      "description" = "Allow inbound traffic to time-api and necessary outbound traffic"
    }
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
      ports {
        port     = "80"
        protocol = "TCP"
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }

    egress {
      to {
        ip_block {
          cidr   = "0.0.0.0/0"
          except = ["169.254.169.254/32"] # Blocking metadata API access
        }
      }
    }

    egress {
      to {
        namespace_selector {}
      }
      ports {
        port     = 53
        protocol = "UDP"
      }
      ports {
        port     = 53
        protocol = "TCP"
      }
    }

    egress {
      to {
        namespace_selector {}
      }
      ports {
        port     = 443
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_ingress_v1" "time_api_ingress" {
  metadata {
    name      = "time-api-ingress"
    namespace = kubernetes_namespace.time_api.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                 = "gce"
      "kubernetes.io/ingress.global-static-ip-name" = "time-api-ingress-ip"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.time_api.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
