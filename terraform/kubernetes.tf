data "google_client_config" "default" {}

data "google_container_cluster" "my_cluster" {
  name     = module.gke.cluster_name
  location = var.region
  project  = var.project_id
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
}

provider "kubectl" {
  host                   = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
  load_config_file       = false
}

module "kubernetes_resources" {
  source           = "./modules/kubernetes_resources"
  project_id       = var.project_id
  region           = var.region
  image_tag        = var.image_tag
  cluster_name     = module.gke.cluster_name
  cluster_endpoint = data.google_container_cluster.my_cluster.endpoint
}
