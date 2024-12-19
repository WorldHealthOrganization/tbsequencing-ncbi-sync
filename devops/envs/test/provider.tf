provider "aws" {
  region = local.aws_region
}

terraform {
  backend "s3" {
    bucket         = "fdx-main-test-tf-state"
    dynamodb_table = "fdx-main-test-tf-state-lock"
    key            = "ncbi/terraform.tfstate"
    region         = "eu-west-1"
  }
}

provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}
