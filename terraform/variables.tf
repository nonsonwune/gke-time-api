variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "zone" {
  description = "The zone to deploy resources"
  type        = string
  default     = "us-central1-a"
}

variable "gke_num_nodes" {
  description = "Number of nodes in the GKE cluster"
  type        = number
  default     = 2
}

variable "image_tag" {
  description = "The tag of the Docker image to deploy"
  type        = string
}
