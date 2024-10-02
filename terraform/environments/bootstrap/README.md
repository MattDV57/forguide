# Drive Transfer Service: Project Bootstrap

1. To run the Drive Transfer Service Bootstrap step, your user should have the following IAM roles on the existing project:
    - Owner *(only recommended if you created the project and this is the default IAM role given to your user)*

      **--OR--**

    - Cloud Build Editor
    - Storage Admin
    - Service Usage Admin
    - Secret Manager Admin
    - Artifact Registry Admin
    - Service Account Admin
    - Project IAM Admin
    - OAuth Config Editor

2. From your local machine, authenticate through the `gcloud` CLI:
    ```
    gcloud auth login
    gcloud auth application-default login
    gcloud config set project mattdv-rclone
    ```

3. [Install Terraform](https://developer.hashicorp.com/terraform/install) and also [install tfenv](https://github.com/tfutils/tfenv) package to make it easier to switch to the correct version of Terraform (1.9.5). Run the following commands:
    ```
    tfenv install 1.9.5
    tfenv use 1.9.5
    ```

4. Perform a "find-and-replace" in the  repository for the below values. Most of the values are also marked with `#TODO: STEP 4`. DO NOT replace any values in the README.md files or in the `terraform/modules/` directories:
    - `0189FA-E139FD-136A58` (Can be found in GCP Console -> Billing, i.e. `XXXXXX-XXXXXX-XXXXXX`)
    - `mattdv-rclone` (Can be found in GCP Console -> Cloud overview -> Dashboard)
    - `122648953585` (Can be found in GCP Console -> Cloud overview -> Dashboard)
    - `themicrolab.joonix.net` (Domain associated with the Google Workspace instance, i.e. `example.com`)
    - `alladmins@themicrolab.joonix.net` (Google Group email address that contains "admin" users, i.e. `drive-transfer-service-admins@example.com`)
    - `us-central1` (GCP region where you would like to deploy your resources, i.e. `us-central1`)
    - `mdv` (3-7 character prefix that will be used to name some resources, i.e. `dts`)
    - `dev` (the environment you will be deploying this solution to, i.e. `dev`, `uat`, `prod`)

5. Rename the `terraform/environments/env` directory to `terraform/environments/dev`.

6. From within the `terraform/environments/bootstrap/` directory, run the following:
    ```
    terraform init
    terraform plan
    terraform apply
    ```

    This step enables project APIs, creates Terraform and project Service Accounts, a Terraform state Google Cloud Storage bucket, a few Secret Manager secrets to store credentials, and Artifact Registry repositories. The output of `terraform apply` should look like this:
    ```
    common_config = {
      "billing_account_id" = "0189FA-E139FD-136A58"
      "bootstrap_project_id" = "mattdv-rclone"
      "default_prefix" = "mdv"
      "default_region" = "us-central1"
      "tf_service_account" = "sa-drive-transfer-service-tf@mattdv-rclone.iam.gserviceaccount.com"
      "tf_state_bucket" = "bkt-mdv-dts-tf-state"
    }
    secret_manager_secrets = {
      ...
    }
    service_accounts = {
      ...
    }
    ```

7. Remove the `.example` suffix from `backend.tf` and make sure the `bucket` attribute matches the `tf_state_bucket` value in previous command output.

8. In `terraform.tfvars` uncomment the `terraform_sa` line (marked with `#TODO: STEP 8`)  and make sure the email matches the `tf_service_account` value in previous command output. Remove the `.example` suffix from `providers.tf`.

9. Remove the `.example` suffix from the `network.tf` file. You also should set IP CIDR block values in `terraform/environments/bootstrap/networks.tf.example` so they do not overlap with existing subnets and uncomment the `vpc_network` attribute in `outputs.tf` (marked with `#TODO: STEP 9`).

10. Setup the CI/CD pipelines for the Terraform, API, and UI. CI/CD pipelines are defined for either Secure Source Manager, Github, or Gitlab Enterprise. Remove the `.example` suffix **ONLY** from the appropriate `cloudbuild_*.tf` file (Secure Source Manager does not have one as the triggers are defined in `.cloudbuild/triggers.yaml`), populate the appropriate Secret Manager secrets, and replace any placeholder values:
    
    ### Secure Source Manager
      - Ensure you have a Secure Source Manager instance provisioned(https://cloud.google.com/secure-source-manager/docs/create-instance) for your organization.
      - Uncomment "securesourcemanager.googleapis.com" in `terraform.tfvars`. Remove the commented lines from the following files marked `#TODO: STEP 10`:
        - `assets/iam.yaml`
        - `assets/sa.yaml`
      - The Cloud Build triggers for Secure Source Manager are defined in `.cloudbuild/triggers.yaml`. Simply push your repository to the remote `main` branch for the Cloud Build triggers to run:
        ```git add .
        git commit -m "Initial commit"
        git push origin main
        ```

    ### Github (`cloudbuild_github.tf`)
      - [Install the Cloud Build GitHub App](https://github.com/apps/google-cloud-build) on your GitHub account or in an organization you own.
      - [Create a personal access token (classic)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token). Make sure to set your token to have no expiration date and select the following permissions when prompted in GitHub: `repo` and `read:user`. If your app is installed in an organization, make sure to also select the `read:org` permission.
      - Save this value in the `github-pat` Secret Manager secret.
      - Replace the following placeholders in `cloudbuild_github.tf`:
        - `https://github.com/MattDV57/forguide.git` (The full HTTPS URI that you would use to `git clone` the repository, i.e. `https://github.com/my-org/my-repo.git`)
        - `MattDV57` (The GitHub organization name, i.e. `my-org`)
        - `[GITHUB_REPO_NAME]` (The GitHub repository name, i.e. `my-repo`)
        - `main` (The branch name that you want to trigger Cloud Builds from, i.e. `main`)
        - `55524472` (The Installation ID of your "Cloud Build GitHub" app. Your Installation ID can be found in the URL of your Cloud Build GitHub App. You can find this value by navigating to your repository's "Settings" > "GitHub Apps" > "Google Cloud Build" > "Configure". In the URL, `https://github.com/settings/installations/1234567`, the Installation ID is the numerical value `1234567`)
      - Navigate to `https://console.cloud.google.com/cloud-build/triggers;region=global/connect?project=mattdv-rclone` to finish connecting Github to your project. Ensure you select the same region for the connection as the triggers (i.e. us-central1).

    ### Gitlab Enterprise (`cloudbuild_gitlab.tf`):
      - On the GitLab Enterprise Edition page for your instance, click on your avatar in the upper-right corner. Click Edit profile, then select Access tokens.
      - Create an access token with the `api` scope to use for connecting and disconnecting repositories. Save this value in the `gitlab-api-pat` Secret Manager secret.
      - Create another access token with the `read_api` scope to ensure Cloud Build repositories can access source code in repositories. Save this value in the `gitlab-read-pat` Secret Manager secret.
      - Create a random 20 character string to use as a Webhook Secret and save this value in the `gitlab-webhook-secret` Secret Manager secret. Below is an example command to generate this key (on MacOS):

        ```
        openssl rand -base64 20 |md5 |head -c20;echo
        ```
      - Replace the following placeholders in `cloudbuild_gitlab.tf`:
        - `[GITLAB_HOST_URI]` (The URI of the GitLab Enterprise host this connection is for, i.e. `https://gitlab.example.com`)
        - `[GITLAB_REPO_URI]` (The full HTTPS URI that you would use to `git clone` the repository, i.e. `https://gitlab.com/my-org/my-repo.git`)
        - `main` (The branch name that you want to trigger Cloud Builds from, i.e. `main`)
      - Navigate to `https://console.cloud.google.com/cloud-build/triggers;region=global/connect?project=mattdv-rclone` to finish connecting Gitlab to your project. Ensure you select the same region for the connection as the triggers (i.e. us-central1).

11. From within the `terraform/environments/bootstrap/` directory, run the `terraform init` command again. You will get a messsage asking if you want to migrate the Terraform state:

    ```
    Initializing the backend...
    Do you want to copy existing state to the new backend?
      Pre-existing state was found while migrating the previous "local" backend to the
      newly configured "gcs" backend. No existing state was found in the newly
      configured "gcs" backend. Do you want to copy this state to the new "gcs"
      backend? Enter "yes" to copy and "no" to start with an empty state.

      Enter a value:
    ```

    Enter `yes ` and then Enter. Then proceed running:

    ```
    terraform plan
    terraform apply
    ```

12. Push the entire local repository to your remote repository's `main` branch (i.e. `main`)and make sure the Cloud Build triggers automatically start. At this step, the only Cloud Build triggers that should succeed are the `drive-transfer-service-api-deploy`, `terraform-builder-deploy`, and  `gcs-fuse-sidecar-deploy` triggers. The others will be run manually in a later step.

[!IMPORTANT]
You should now return to the repository root [README file](../../../README.md) and continue from Step 5.