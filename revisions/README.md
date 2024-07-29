# AR.IO Revisions

CodeDeploy requires these revisions.

To create a new revision:

1. Run `scripts/prepare-revision <VERSION>`
2. Copy the new `docker-compose.yaml` from the `ar-io/ar-io-node` GitHub repo
   into your newly created revision source folder.
   (e.g., `revisions/<VERSION>/source`)
   - delete replace all `build:`
   - add `pull_policy: always` to the services
   - update the `AR_IO_NODE_RELEASE` environment variable
     to reflect the revision.

The `scripts/deploy-revision <VERSION>` will package the folder and upload it to
S3 and create a new CodeDeploy deployment with the revision.
