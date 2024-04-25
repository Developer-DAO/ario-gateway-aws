# AR.IO Gateway Infrastructure

This repository contains Terraform templates which define resources to host an
AR.IO gateway.

The domains are managed with Vercel, the rest is hosted on AWS.

## Environment Variables

There are two kinds of environment variables, those for Terraform and those for
the AR.IO gateway. The Terraform variables are used to configure the AWS and
Vercel providers. The AR.IO gateway variables are used to configure the gateway

### Terraform Deploy

You can define Terraform inputs and provider API keys via environment variables.
This allows to keep the secrets out of the Terraform configuration files and use
GitHub Actions to deploy the infrastructure.

Copy the `resources/template.env.terraform` to
`resources/.env.terraform` and fill in the values.

### AR.IO Gateway Configuration

Terraform will copy the gateway config file in SSM Parameter Store, allowing the
gateway instances to fetch them at boot time.

Copy the `resources/template.env.gateway` to
`resources/.env.gateway` and fill in the values.

## Commands

These commands will use the environment variables from
`resources/.env` files.

Plan the deployment and save the plan into a file:

    scripts/plan

Deploy the infrastructure from the plan file:

    scripts/apply

Destroy the infrastructure:

    scripts/destroy

Update to a new release:

    scripts/update <REVISION>

Create a new revision in the `revisions` folder before running this command.