variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The region to deploy resources"
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  type        = string
}

variable "image_tag" {
  description = "The tag of the Docker image to deploy"
  type        = string
}
