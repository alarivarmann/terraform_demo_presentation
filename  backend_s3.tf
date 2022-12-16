terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.46"
    }
  }
  backend "s3" {
    bucket  = "homie-state-bucket"
    key     = "terraform.tfstate"
    region  = "eu-central-1"
    profile = "dev"
    encrypt = true
  }

  # Only allow this Terraform version. Note that if you upgrade to a newer version, Terraform won't allow you to use an
  # older version, so when you upgrade, you should upgrade everyone on your team and your CI servers all at once.
  required_version = ">= 1.3.5"

}

provider "aws" {
  region                   = "eu-central-1"
  profile                  = "dev"
  shared_credentials_files = ["~/.aws/credentials"]
}

data "aws_availability_zones" "available" { state = "available" }
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
