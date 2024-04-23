# AR.IO Gateway AWS Infrastructure

This repository contains Terraform templates which define resources to host an
AR.IO gateway.

The domains are managed with Vercel, the rest is hosted on AWS.

## Environment Variables

### Terraform Deploy

Define the Terraform inputs and provider API keys via environment variables.

You can copy the `template.env` to `.env.<ENVIRONMENT>` and fill in the values.

### AR.IO Gateway Configuration

The AR.IO gateway configuration is stored under `resources/.env.gateway`

## Commands

Plan the deployment and save the plan into a file:

    ./scripts/plan <ENVIRONMENT>

Deploy the infrastructure from the plan file:

    ./scripts/apply <ENVIRONMENT>

Destroy the infrastructure:

    ./scripts/destroy <ENVIRONMENT>
