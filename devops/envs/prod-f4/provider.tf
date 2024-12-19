provider "aws" {
  default_tags {
    tags = local.tags
  }
}

terraform {
  backend "s3" {
    bucket         = "fdx-main-prod-f4-tf-state"
    dynamodb_table = "fdx-main-prod-f4-tf-state-lock"
    key            = "ncbi/terraform.tfstate"
    region         = "us-east-1"
  }
}
