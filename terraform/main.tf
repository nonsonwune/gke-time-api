# terraform/main.tf

module "networking" {
  source     = "./modules/networking"
  project_id = var.project_id
  zone       = var.zone
  vpc_name   = "${var.project_id}-vpc"
}

module "gke" {
  source        = "./modules/gke"
  project_id    = var.project_id
  region        = substr(var.zone, 0, length(var.zone) - 2)
  vpc_name      = module.networking.vpc_name
  subnet_name   = module.networking.subnet_name
  gke_num_nodes = var.gke_num_nodes
}

module "kubernetes_resources" {
  source                 = "./modules/kubernetes_resources"
  project_id             = var.project_id
  zone                   = var.zone
  image_tag              = var.image_tag
  vpc_name               = module.networking.vpc_name
  subnet_name            = module.networking.subnet_name
  cluster_endpoint       = module.gke.cluster_endpoint
  cluster_ca_certificate = module.gke.cluster_ca_certificate
  depends_on             = [module.gke]
}
