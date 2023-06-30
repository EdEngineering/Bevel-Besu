terraform {
  backend "gcs" {
    bucket = "ansible-bevel-testing-bucket"
    prefix = "terraform/state"
  }
}