provider "kubernetes" {
  host                   = "https://${module.gke.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
}

provider "kubectl" {
  host                   = "https://${module.gke.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  load_config_file       = false
}

module "kubernetes_resources" {
  source           = "./modules/kubernetes_resources"
  project_id       = var.project_id
  region           = var.region
  image_tag        = var.image_tag
  cluster_name     = module.gke.cluster_name
  cluster_endpoint = module.gke.cluster_endpoint
}
