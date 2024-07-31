terraform {
  backend "s3" {
    region = "us-west-2"
    dynamodb_table = "ar-io-gateway-terraform-state"
    bucket = "ar-io-gateway-terraform-state"
    key = "ar-io-gateway.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}