data "terraform_remote_state" "gke" {
  backend = "gcs"
  config = {
    bucket = "time-api-gke-project-434215-tfstate"
    prefix = "terraform/state"
  }
}

data "google_container_cluster" "my_cluster" {
  name     = data.terraform_remote_state.gke.outputs.cluster_name
  location = var.region
  project  = var.project_id
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
}

module "kubernetes_resources" {
  source           = "./modules/kubernetes_resources"
  project_id       = var.project_id
  region           = var.region
  image_tag        = var.image_tag
  cluster_name     = data.terraform_remote_state.gke.outputs.cluster_name
  cluster_endpoint = data.google_container_cluster.my_cluster.endpoint
}
