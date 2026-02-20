terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.84"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = module.context.tags
  }
}
