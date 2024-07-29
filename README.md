# AR.IO Gateway Infrastructure

This repository contains Terraform templates which define resources to host an
AR.IO gateway on AWS.

The domains are managed with Vercel, the rest is hosted on AWS.

> Note: Current version used for first deploy is 15. This version is defined in
> [resources/userdata.sh](resources/userdata.sh:144) and should be updated when
> new releases are available.

## Environment Variables

There are two kinds of environment variables:

1. Variables used by Terraform at deployment time.
2. Variables used by the AR.IO gateway instances at runtime.

### Terraform Deploy

Define Terraform inputs and provider API keys via environment variables.

This allows to keep the secrets out of the Terraform configuration files and use
GitHub Actions to deploy the infrastructure.

Copy `resources/template.env.terraform` to `resources/.env.terraform` and fill
in the values to configure the Terraform deployment.

### AR.IO Gateway Configuration

Terraform will encrypt and upload `resources/.env.gateway` into the SSM
Parameter Store, allowing the gateway instances to fetch them at boot time.

Copy the `resources/template.env.gateway` to `resources/.env.gateway` and fill
in the values.

## Infrastructure Deployment

These commands will use the environment variables from
`resources/.env.terraform`.

### Plan

Plan the deployment and save the plan into a file.

    scripts/plan

### Apply

Deploy the infrastructure from the plan file and save the outputs into
`resources/outputs`.

    scripts/apply

### Destroy

Delete all AWS resources.

    scripts/destroy

## Gateway Updates

You don't need to redeploy the infrastructure to update the gateway. The
follwing commands will just stop each instance and update it.

### Update Gateway

These commands will create an archive with the a new revision of the gateway,
upload it to S3 and update the instances via CodeDeploy.

#### Creating an Update

To create a new update from a template if the version you need doesn't exist yet.

    scripts/prepare-revision <VERSION>

After running this command follow these steps:

- Copy the new `docker-compose.yaml` from the `ar-io/ar-io-node` GitHub repo
  into your newly created revision source folder. (e.g.,
  `revisions/<VERSION>/source`)
- delete `build:` from each service
- add `pull_policy: always` to each service
- update the `AR_IO_NODE_RELEASE` environment variable to reflect the revision.

#### Deploying an Update

To archive, upload, and deploy the update:

    scripts/deploy-revision <VERSION>

## SSH Access

SSM Session Manager is the only way to SSH into the instances.
