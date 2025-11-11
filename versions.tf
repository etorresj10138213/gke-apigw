terraform {
  backend "gcs" {
    bucket = "consalud-terraform-bucket"
    prefix = "gke-apigw/dev"
  }
  required_version = ">= 1.5.0" # Asegura la compatibilidad con tu versión de GitHub Actions
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
provider "google" {
  region = "us-east1" 
  zone   = "us-esast1-a"
}
