# AR.IO Revisions

CodeDeploy requires these revisions.

To create a new revision:

1. Copy an old revision folder
2. Rename it with the new revision (e.g., r10, r11-pre, etc.)
3. Update the source/docker-compose.yml file with the new image tags. You can
   copy the one from the ar-io/ar-io-node GitHub repo, but delete the
   "build:" and add "pull_policy: always" to the services. to ensure the new
   image is downloaded. Also, update the AR_IO_NODE_RELEASE environment variable
   to reflect the revision.

The `scripts/update <REVISION>` will package the folder and upload it to S3 and
create a new CodeDeploy deployment with the revision.
