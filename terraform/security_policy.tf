# terraform/security_policy.tf

resource "google_compute_security_policy" "policy" {
  name = "time-api-security-policy"

  # Default rule (required)
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule, higher priority overrides it"
  }

  # Original rule
  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["0.0.0.0/0"]
      }
    }
    description = "Allow all traffic"
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
  depends_on = [google_container_cluster.time_api_cluster, null_resource.check_gke_plugin]

  provisioner "local-exec" {
    command     = <<EOT
      gcloud container clusters get-credentials ${google_container_cluster.time_api_cluster.name} --zone ${google_container_cluster.time_api_cluster.location} --project ${var.project_id}
      kubectl apply -f network_policy.yaml --validate=false
    EOT
    working_dir = path.module
  }
}
