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
  backend "gcs" {
    bucket = "time-api-gke-project-434215-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_compute_network" "existing_vpc" {
  name    = "time-api-vpc"
  project = var.project_id
}

module "networking" {
  source     = "./modules/networking"
  project_id = var.project_id
  region     = var.region
  vpc_name   = data.google_compute_network.existing_vpc.name
}

module "gke" {
  source        = "./modules/gke"
  project_id    = var.project_id
  region        = var.region
  vpc_name      = data.google_compute_network.existing_vpc.name
  subnet_name   = module.networking.subnet_name
  gke_num_nodes = var.gke_num_nodes
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

resource "null_resource" "check_gke_plugin" {
  provisioner "local-exec" {
    command = <<EOT
      if ! command -v gke-gcloud-auth-plugin &> /dev/null; then
        echo "Error: gke-gcloud-auth-plugin not found. Please install it before applying Terraform."
        exit 1
      fi
    EOT
  }
}
