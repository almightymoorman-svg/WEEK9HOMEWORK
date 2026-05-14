# 1-main.tf
# Entry point — defines the Terraform version requirements and the GCP provider.

terraform {
  # Require at least Terraform 1.10 to ensure compatibility with features used here
  required_version = ">= 1.10"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0" # Latest stable 6.x line as of 2025
    }
  }
}

# Provider block — uses default values where possible.
# Project and region are pulled from variables so this config is reusable.
provider "google" {
  project = "var.project_id"
  region  = "var.region"
}
