terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "xomware-terraform-state"
    key            = "dominickgiordano/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "xomware-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  standard_tags = {
    "source"      = "terraform"
    "app_name"    = var.app_name
    "environment" = "production"
    "owner"       = "domgiordano"
  }
}
