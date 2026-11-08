terraform {
  backend "s3" {
    bucket       = "much-to-do-terraform-state-252556588618"
    key          = "much-to-do/terraform.tfstate"
    region       = "us-east-1"
    profile      = "terraform-admin"
    encrypt      = true
    use_lockfile = true
  }
}