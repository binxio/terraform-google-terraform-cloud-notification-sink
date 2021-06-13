variable "project" {
  default = "speeltuin-mvanholsteijn"
}

variable "region" {
  default = "europe-west1"
}
provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}

data "google_project" "default" {
}
