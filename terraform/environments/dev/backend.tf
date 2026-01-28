terraform {
  backend "s3" {
    bucket         = "gitops-platform-terraform-state-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "gitops-platform-terraform-locks"
  }
}
