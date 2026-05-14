# 2-variables.tf
# All input variables are defined here. Set these in a terraform.tfvars file
# or pass them in via -var flags. No secrets are hardcoded.

variable "project_id" {
  description = "GCP project ID to deploy resources into"
  type        = string
}

variable "region" {
  description = "GCP region for regional resources (MIG, subnet, etc.)"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for the MIG — should be within the region above"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "Name for the custom VPC network"
  type        = string
  default     = "hw8-vpc"
}

variable "subnet_name" {
  description = "Name for the subnet inside the VPC"
  type        = string
  default     = "hw8-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for the primary subnet"
  type        = string
  default     = "10.10.0.0/24"
}

variable "mig_name" {
  description = "Name for the Managed Instance Group"
  type        = string
  default     = "hw8-mig"
}

variable "instance_template_name" {
  description = "Name for the instance template used by the MIG"
  type        = string
  default     = "hw8-instance-template"
}

variable "machine_type" {
  description = "GCE machine type for MIG instances — e2-micro is free-tier eligible and sufficient for this demo"
  type        = string
  default     = "e2-micro"
}

variable "mig_min_replicas" {
  description = "Minimum number of instances in the MIG (autoscaler lower bound)"
  type        = number
  default     = 2
}

variable "mig_max_replicas" {
  description = "Maximum number of instances the autoscaler can create"
  type        = number
  default     = 5
}
