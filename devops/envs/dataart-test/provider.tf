provider "aws" {
  region = local.aws_region
}

terraform {
  backend "s3" {
    bucket         = "fdx-main-dataart-test-tf-state"
    dynamodb_table = "fdx-main-dataart-test-tf-state-lock"
    key            = "ncbi/terraform.tfstate"
    region         = "eu-west-1"
  }
}
