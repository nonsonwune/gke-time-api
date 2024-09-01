terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = "https://${module.gke.cluster_endpoint}"
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gke-gcloud-auth-plugin"
  }
}

module "networking" {
  source     = "./modules/networking"
  project_id = var.project_id
  region     = var.region
}

module "gke" {
  source        = "./modules/gke"
  project_id    = var.project_id
  region        = var.region
  vpc_name      = module.networking.vpc_name
  subnet_name   = module.networking.subnet_name
  gke_num_nodes = var.gke_num_nodes
}

module "kubernetes_resources" {
  source           = "./modules/kubernetes_resources"
  project_id       = var.project_id
  region           = var.region
  cluster_name     = module.gke.cluster_name
  cluster_endpoint = module.gke.cluster_endpoint
  image_tag        = var.image_tag

  depends_on = [module.gke]
}

resource "google_project_service" "services" {
  for_each = toset([
    "container.googleapis.com",
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])
  project = var.project_id
  service = each.key

  disable_on_destroy = false
}
