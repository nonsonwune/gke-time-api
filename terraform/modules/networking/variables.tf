variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "zone" {
  description = "The zone to deploy resources"
  type        = string
}

variable "vpc_name" {
  description = "The name of the existing VPC"
  type        = string
}
