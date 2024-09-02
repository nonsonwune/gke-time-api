variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "zone" {
  description = "The zone to deploy resources"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "image_tag" {
  description = "The image tag for the application"
  type        = string
}

variable "cluster_endpoint" {
  description = "The cluster endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "The cluster CA certificate"
  type        = string
}
