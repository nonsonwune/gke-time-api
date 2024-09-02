# terraform/policies.tf

# Prevent destruction of the GKE cluster
resource "null_resource" "prevent_cluster_destroy" {
  lifecycle {
    prevent_destroy = true
  }

  triggers = {
    cluster_name = module.gke.cluster_name
  }

  depends_on = [module.gke]
}

# Set up monitoring alert for high CPU utilization
resource "google_monitoring_alert_policy" "high_cpu_usage" {
  project      = var.project_id
  display_name = "High CPU Usage Alert"
  combiner     = "OR"
  conditions {
    display_name = "CPU Usage Condition"
    condition_threshold {
      filter          = "metric.type=\"kubernetes.io/node/cpu/allocatable_utilization\" AND resource.type=\"k8s_node\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8 # 80% CPU utilization
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  user_labels = {
    severity = "warning"
  }

  depends_on = [module.gke, module.kubernetes_resources]
}

# Set up email notification channel
resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Email Notification Channel"
  type         = "email"
  labels = {
    email_address = "chuqunonso@gmail.com"
  }
}

# Add lifecycle policy to the GKE cluster
resource "null_resource" "gke_cluster_lifecycle" {
  triggers = {
    cluster_name = module.gke.cluster_name
  }

  provisioner "local-exec" {
    command = "echo 'Preventing destruction of GKE cluster: ${module.gke.cluster_name}'"
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [module.gke]
}
