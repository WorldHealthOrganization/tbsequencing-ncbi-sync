provider "aws" {
  region = local.aws_region
}

terraform {
  backend "s3" {
    bucket         = "fdx-main-db-for-prod-tf-state"
    dynamodb_table = "fdx-main-db-for-prod-tf-state-lock"
    key            = "ncbi/terraform.tfstate"
    region         = "us-east-1"
  }
}
