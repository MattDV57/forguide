<<<<<<< HEAD
1) In the `terraform/environments/[ENVIRONMENT]/` directory change the following values marked with `#TODO: STEP 4`. Most of these changes include changing the Environment, Project ID, Project Number, or the GCP Bucket Names (that follow the following naming conventions):
`bkt-[PREFIX]-dts-tf-state`

2) Run the following `git` commands to commit and tag your changes and push to the remote repository to trigger automated deployments:
```
cd terraform/environments/[ENVIRONMENT]
git add .
git commit -m "Initial environment deployment"
git push origin main
git tag -a tf-plan-[ENVIRONMENT]-MMDDYY-HHMM -m "Initial environment deployment"
git push origin tf-plan-[ENVIRONMENT]-MMDDYY-HHMM
```

When the Terraform Plan Cloud Build trigger finishes successfully, run the following commands to apply the changes:
```
git tag -a tf-apply-[ENVIRONMENT]-MMDDYY-HHMM -m "Initial environment deployment"
git push origin tf-apply-[ENVIRONMENT]-MMDDYY-HHMM
```

3) In the Google Cloud Console, navigate to Secret Manager and create new Secret Versions for the following Secrets. You can find the values to populate these secrets in the "APIs & Services -> Credentials" screen:
`rclone-admin-oauth-client-id` (`Drive Transfer Service API - Admin Transfers` Client ID)
`rclone-admin-oauth-client-secret` (`Drive Transfer Service API - Admin Transfers` Client Secret)
`rclone-ui-oauth-client-id` (`Drive Transfer Service UI - IAP/Auth` Client ID)
`rclone-ui-oauth-client-secret` (`Drive Transfer Service UI - IAP/Auth` Client Secret)

4) In the Google Cloud Console, navigate to Service Accounts and generate a JSON key for the `sa-rclone-admin-transfers@[PROJECT_ID].iam.gserviceaccount.com`  Service Account. Copy the contents of the downloaded JSON file into the `sa-rclone-admin-transfers-key` Secret in Secret Manager.

5) Uncomment all resources under STEP 2 in `main.tf` and then commit, tag and push your changes to the repository (follow Step 2 above) to deploy the next set of resources.

6) Uncomment all resources under STEP 3 in `main.tf` and replace [CLOUD_RUN_URI] with the auto-provisioned URI for the `drive-transfer-service-api` Cloud Run Service (without the `https://`) then commit, tag and push your changes to the repository (follow Step 2 above) to deploy the next set of resources.
=======
# Drive Transfer Service: Project Environment

1) Before running this deployment, please complete the following pre-requisites:

    1.1. Follow the steps in [terraform/environments/bootstrap/README.md](../bootstrap/README.md)

    1.2. In the Google Cloud Console, navigate to "Secret Manager" and create new Secret Versions for the following Secrets. You can find the values to populate these secrets in the "APIs & Services" -> "Credentials" screen:
    - `rclone-admin-oauth-client-id` (Drive Transfer Service API - Admin Transfers Client ID)
    - `rclone-admin-oauth-client-secret` (Drive Transfer Service API - Admin Transfers Client Secret)
    - `rclone-ui-oauth-client-id` (Drive Transfer Service UI - IAP/Auth Client ID)
    - `rclone-ui-oauth-client-secret` (Drive Transfer Service UI - IAP/Auth Client Secret)
    - `group-job-user-limit` (Number of users allowed in a Google Group transfer job)

    1.3. Run the `[ENVIRONMENT]-terraform-apply-deploy` Cloud Build trigger. You can manually run the trigger from the GCP console > “Cloud Build” > “Triggers”.

2) You may proceed to the next step in the Deployment Guide.
>>>>>>> 99f04a3 (testiong)
