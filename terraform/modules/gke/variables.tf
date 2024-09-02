# terraform/modules/gke/variables.tf

variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The region to deploy resources"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "gke_num_nodes" {
  description = "Number of nodes in the GKE cluster"
  type        = number
  default     = 2
}
