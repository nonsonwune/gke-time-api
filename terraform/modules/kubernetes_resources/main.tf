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
        }
      }
    }
  }
  depends_on = [kubernetes_namespace.time_api, var.cluster_endpoint]
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
  depends_on = [kubernetes_deployment.time_api, var.cluster_endpoint]
}
