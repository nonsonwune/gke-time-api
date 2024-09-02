# terraform/variables.tf

variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "zone" {
  description = "The zone to deploy resources"
  type        = string
}

variable "gke_num_nodes" {
  description = "Number of nodes in the GKE cluster"
  type        = number
}

variable "image_tag" {
  description = "The tag of the Docker image to deploy"
  type        = string
}
