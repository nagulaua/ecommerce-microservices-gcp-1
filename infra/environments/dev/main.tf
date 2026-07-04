terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Where Terraform stores its "state" file — for now, local disk.
  # Later, we'll move this to a GCS bucket so state is shared/safe for teams.
}

provider "google" {
  project = var.project_id
  region  = var.region
}