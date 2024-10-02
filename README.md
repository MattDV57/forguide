# Drive Transfer Service

> [!IMPORTANT]
> This Deployment Guide assumes that a GCP project is already provisioned and associated with a Billing Account. Because Drive is provisioned for the entire Workspace Domain (i.e. example.edu), one “production” environment is all that is needed. However, some customers have utilized subdomains (i.e. nomn-prod.example.edu)  and have an instance of Drive that they can use for testing/developing in a “non-production” environment. 

> [!IMPORTANT]
> A Super Admin for your Workspace domain will need to assist towards the end of deployment with creating a Drive Transfer Service user and granting Service Accounts Domain-wide delegation from within the [Admin Console](https://admin.google.com).

## Prerequisites

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

2. [Setup the OAuth Consent Screen](https://developers.google.com/workspace/guides/configure-oauth-consent) for your project in the GCP Console.
    | FIELD | VALUE |
    |---|---|
    | User Type | Internal |
    | App name | Drive Transfer Service |
    | Authorized domains | mattdv-rclone.uc.r.appspot.com |
    | Scopes | _(skip for now)_ |

3. [Setup two OAuth Client ID/Secrets](https://developers.google.com/workspace/guides/create-credentials#oauth-client-id) (one for Drive Transfer Service UI &  one for Drive Transfer Service API). You should note down the Client ID/Client Secret for each of these credentials - we will come back to these later. Use the recommended values below:

    ### "Drive Transfer Service API" OAuth Credentials:

    | FIELD | VALUE |
    |---|---|
    | Type | Desktop App |
    | Name | `Drive Transfer Service API - Admin Transfers` |

    ### "Drive Transfer Service UI" OAuth Credentials:

    | FIELD | VALUE |
    |---|---|
    | Type | Web Application |
    | Name | Drive Transfer Service UI - IAP/Auth |
    | Authorized Javascript Origins | `http://localhost`, `http://localhost:5000`, `https://mattdv-rclone.uc.r.appspot.com` |
    | Authorized Redirect URIs | `https://mattdv-rclone.uc.r.appspot.com` |

    After creating the "Drive Transfer Service UI - IAP/Auth" credentials, copy the Client ID value into the following URI. Go back in to edit "Drive Transfer Service UI - IAP/Auth" Credentials and add the URI to the Authorized Redirect URIs list:
    `https://iap.googleapis.com/v1/oauth/clientIds/[INSERT CLIENT ID AFTER GENERATED]:handleRedirect`

## Deploy GCP resources
4. Navigate to the Terraform Bootstrap step [README file](terraform/environments/bootstrap/README.md) and run through all of the steps.

5. In the [GCP Console](https://console.cloud.google.com), navigate to **Secret Manager** > click the **[SECRET_NAME]** from the table below > **+NEW VERSION** > add the corresponding **SECRET_VALUE**. Most of these values will be found in the **APIs & Services** -> **Credentials** screen:

    | SECRET_NAME                      | SECRET_VALUE                                                  |
    |----------------------------------|---------------------------------------------------------------|
    | rclone-admin-oauth-client-id     | “Drive Transfer Service API - Admin Transfers”  Client ID     |
    | rclone-admin-oauth-client-secret | “Drive Transfer Service API - Admin Transfers”  Client Secret |
    | rclone-ui-oauth-client-id        | “Drive Transfer Service UI - IAP/Auth”  Client ID             |
    | rclone-ui-oauth-client-secret    | “Drive Transfer Service UI - IAP/Auth”  Client Secret         |
    | group-job-user-limit             | 20                                                            |

> [!WARNING]
> Group Jobs can have high resource utilization and high costs. Set the Group Job user limit to a conservative numeric value (i.e. 20) until you understand the estimated resource usage/costs of each transfer.

6. In the [GCP Console](https://console.cloud.google.com), navigate to **Cloud Build** > **Triggers** > click the **RUN** button for the the `dev-terraform-apply-deploy` Cloud Build Trigger. This will deploy the remaining solution components including the Drive Transfer Service API (Cloud Run), Cloud Workflows, and Kueue Job Cluster (Google Kubernetes Engine). 
**This build pipeline can take 10+ minutes the first time you run it.**

7. Navigate to the [Firebase Console](https://console.firebase.google.com/) and ensure your project appears and is able to be selected. Select your project and accept the Firebase Terms of Service (Firebase ToS). If it doesn’t prompt you to fill out the Terms of Service, you may proceed to the next step. 

8. In the [GCP Console](https://console.cloud.google.com), navigate to **Service Accounts** > click the `sa-rclone-admin-transfers@PROJECT_ID.iam.gserviceaccount.com` Service Account. Click the **KEYS** tab > **ADD KEY** > **Create new key** > **JSON** to generate a JSON key for the `sa-rclone-admin-transfers` Service Account. Copy the contents of the downloaded JSON file into the `sa-rclone-admin-transfers-key` Secret in Secret Manager.
> [!IMPORTANT]
> If you do not have permissions to do this, it may be because of an Organization Policy (`constraints/iam.disableServiceAccountKeyCreation`) or a missing IAM role (Service Account Key Admin). Contact the Super Admin of your GCP organization to grant a temporary exception to this policy.

> [!IMPORTANT]
> Delete the Service Account JSON key from your local machine IMMEDIATELY after uploading it to Secret Manager.

9. In the [GCP Console](https://console.cloud.google.com), navigate to **OAuth Consent Screen** > click **EDIT APP** > scroll down and click **SAVE AND CONTINUE** > **ADD OR REMOVE SCOPES** > copy the below list of API scopes into the textbox under **Manually add scopes** and click **ADD TO TABLE** > **UPDATE**:
    ```
    https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/documents,https://www.googleapis.com/auth/drive,https://www.googleapis.com/auth/drive.metadata,https://www.googleapis.com/auth/userinfo.email
    ```
    Click **SAVE AND CONTINUE** to finish updating the OAuth Consent Screen.

## Grant Workspace Admin roles + Domain wide delegation
10. Create the Drive Transfer Service Workspace Admin user. This must be created as if it were a human user in your organization so that it can add Service Account permissions to source Shared Drives. It is also used to send notification emails using the Mail API. 

    - In the [Google Admin Console](https://admin.google.com), expand **Directory** in the left toolbar > **Users** > **Add new user**. Create the user with the exact details below:

      | FIELD           | VALUE                           |
      |-----------------|---------------------------------|
      | First name      | `Drive Transfer`                |
      | Last name       | `Service`                       |
      | Primary email   | `drive-transfer-service`        |
      | Secondary email | `[YOUR_EMAIL_ADDRESS]`          |

    - Click **ADD NEW USER**. On the next page click **COPY PASSWORD** and save it in the GCP Console Secret Manager Secret named `drive-transfer-service-user-password` for future reference. You will not need to access this account regularly.

    - Back on the Users list, click the newly created “Drive Transfer Service” user’s name to go to the user’s details page. Click **Admin roles and privileges** section > click the "pencil icon" to edit > toggle the **Assigned state** switch to "Assigned" for the “Storage Admin” role > click **SAVE**.

    - Collapse the **Admin roles and privileges** section > scroll down and click the **Licenses** section. Ensure the user has a Google Workspace license that is “Assigned”. This will allow us to use the “Drive Transfer Service” user to send emails via the Mail API.

11. Grant Domain-wide Delegation to Service Accounts responsible for preparing/running the file transfer jobs as a Super Admin user.

    - Navigate to [Google Admin Console](https://admin.google.com), expand **Security** in the left toolbar > **Access and data control** > **API controls** > **MANAGE DOMAIN WIDE DELEGATION**. For the two Service Accounts below, click **Add new** and enter the corresponding Client ID and scope URLs:

> [!TIP]
> The Client ID of each Service Account can be found in the [GCP Console](https://console.cloud.google.com) by navigating to **IAM & Admin** > **Service Accounts** > copy the value in the **OAuth 2 Client ID** column.

### “Drive Transfer Service API” Service Account:
*sa-run-dts-api@mattdv-rclone.iam.gserviceaccount.com*

|  |  |
|---|---|
| Domain-wide delegation purpose | This Service Account must impersonate any user in the Workspace domain to get information about their My Drive, get User/Group information from the Google Admin / Groups APIs, and send email notifications using the Mail API. |
| Required scopes | https://www.googleapis.com/auth/drive, https://www.googleapis.com/auth/admin.directory.user.readonly, https://mail.google.com/ |

### “Super Admin Rclone” Service Account:
*sa-rclone-admin-transfers@mattdv-rclone.iam.gserviceaccount.com*

|  |  |
|---|---|
| Domain-wide delegation purpose | This Service Account must impersonate any user in the Workspace domain to move their My Drive files. |
| Required scopes | https://www.googleapis.com/auth/drive |

12. Grant the “Storage Admin” role to these Service Accounts so they can access Shared Drives. Navigate to [Google Admin Console](https://admin.google.com) -> expand **Account** in the left toolbar > **Admin roles** > click **Storage Admin** role name > click the **Admins** section > **Assign service accounts**. Add the following list of Service Accounts as a comma-separated list:
  ```
  sa-run-dts-api@mattdv-rclone.iam.gserviceaccount.com,sa-rclone-admin-transfers@mattdv-rclone.iam.gserviceaccount.com
  ```

13. In the [GCP Console](https://console.cloud.google.com), decide where the “Super Admin Rclone” Service Account (`sa-rclone-admin-transfers@PROJECT_ID.iam.gserviceaccount.com`) should be allowed to transfer files to in the GCP organization and grant it the “Storage Admin" IAM role at the appropriate level of your GCP Organization hierarchy. This will dictate what Super Admins are allowed to specify as the Google Cloud Storage Destination when configuring a job in the UI.

    - By default the “Super Admin Rclone” Service Account only has Storage Admin for the project that Drive Transfer Service was deployed in.
    - To allow your Super Admin users to set destination buckets at a broader scope, manually grant the “Super Admin Rclone” Service Account (`sa-rclone-admin-transfers@PROJECT_ID.iam.gserviceaccount.com`) the “Storage Admin” IAM role at the Organization-level, at a specific Folder-level, or even at a Project-level.

14. In the [GCP Console](https://console.cloud.google.com), navigate to **Cloud Build** > **Triggers** > click the **RUN** button for the the `drive-transfer-service-ui-deploy` Cloud Build Trigger. This will deploy the App Engine instance with the Drive Transfer Service UI.

15. In the [GCP Console](https://console.cloud.google.com), navigate to **App Engine** > **Settings** > under **Identity-Aware Proxy** click **Configure Now**. In the **App Engine app** row, toggle the **IAP** switch off and then back on again (IAP requires a human user to enable it to work). Finally, navigate to the URL in the **Published** column to start using your Drive Transfer Service instance!

## Points of contact

| GOOGLER       | PROJECT ROLE                   |
|---------------|--------------------------------|
| mintindola    | Engineer - Backend             |
| dixital       | Engineer - Frontend            |
| mattdelvecchio| Engineer - Testing/Performance |
| eriqeiland    | Program Management - Business  |
| yiwenjia      | Program Management - Partner   |
| tntaylor      | Product - Education + Storage  |
