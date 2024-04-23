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