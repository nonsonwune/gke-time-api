# terraform/variables.tf

variable "project_id" {
  description = "project id"
}

variable "project_number" {
  description = "project number"
}

variable "region" {
  description = "region"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}
