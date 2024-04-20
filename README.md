# AR.IO Gateway AWS Infrastructure

This repository contains Terraform templates which define resources to host an
AR.IO gateway.

The domains are managed with Vercel, the rest is hosted on AWS.

## Require Environment Variables

Define the Terraform inputs and provider API keys via environment variables.

    AWS_ACCESS_KEY_ID="ABCDEFG123"
    AWS_SECRET_ACCESS_KEY="ABCDEFG123"
    VERCEL_API_TOKEN="ABCDEFG123"

    TF_VAR_alias="my-gateway"
    TF_VAR_region="eu-west-1"
    TF_VAR_account_id="123456789"

    TF_VAR_domain_name="example.com"
    TF_VAR_subdomain_name="arweave"

    TF_VAR_vpc_id="vpc-123456789"
    TF_VAR_vpc_cidr="172.31.0.0/16"
    TF_VAR_public_subnets='["subnet-123456789"]'
    TF_VAR_private_subnets='["subnet-123456789"]'
    TF_VAR_instance_type="t2.micro"
