# Drive Transfer Service API
<<<<<<< HEAD
Flask API that accepts config and job parameters and invokes Rclone jobs through Cloud Workflows

Trigger automated build/deployment by committing change and tagging with a tag with the pattern `api-[DATE]-[TIME]`:
```
git add .
git commit -m "[COMMIT_MESSAGE]"
git tag -a api-[MMDDYY]-[HHMM] -m "[TAG_MESSAGE]"
git push origin api-[MMDDYY]-[HHMM]
```

This will kick off the Cloud Build trigger `drive-transfer-service-api-deploy` which will build the latest Docker image, store it in Artifact Registry, and create a new Cloud Deploy release that can be promoted across a Cloud Run instance within each environment.
=======

Flask API that accepts config and job parameters and invokes Rclone jobs through Cloud Workflows.

Changes to files in this directory will kick off the Cloud Build trigger `drive-transfer-service-api-deploy` which will build the latest Docker image, store it in Artifact Registry, and create a new Cloud Deploy release that can be promoted across a Cloud Run instance within each environment
>>>>>>> 99f04a3 (testiong)
