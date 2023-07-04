terraform {
  backend "gcs" {
    bucket = "bevel-testing-bucket"
    prefix = "terraform/state"
  }
}