provider "kubernetes" {
  host  = "https://${google_container_cluster.time_api_cluster.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.time_api_cluster.master_auth[0].cluster_ca_certificate
  )
}
