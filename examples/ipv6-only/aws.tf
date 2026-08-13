terraform {
  required_version = ">= 1.10.0" # floor-reason: above-root floor kept as found, reason unrecorded pre-2026-08-13

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
