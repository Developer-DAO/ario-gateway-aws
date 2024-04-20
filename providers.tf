terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    vercel = {
      source  = "vercel/vercel"
      version = "~> 1.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# CloudFront expects SSL certificates in us-east-1
provider "aws" {
  region = "us-east-1"
  alias = "us-east-1"
}

provider "vercel" {
  team = "developdao"
}