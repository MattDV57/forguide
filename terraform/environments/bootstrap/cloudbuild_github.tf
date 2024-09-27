# * Copyright 2024 Google LLC
# *
# * Licensed under the Apache License, Version 2.0 (the "License");
# * you may not use this file except in compliance with the License.
# * You may obtain a copy of the License at
# *
# *      http://www.apache.org/licenses/LICENSE-2.0
# *
# * Unless required by applicable law or agreed to in writing, software
# * distributed under the License is distributed on an "AS IS" BASIS,
# * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# * See the License for the specific language governing permissions and
# * limitations under the License.

resource "google_cloudbuildv2_connection" "github_host_connection" {
  project  = module.project.project_id
  location = var.default_region
  name     = "github-host"

  github_config {
    app_installation_id = "55238649"
    authorizer_credential {
      oauth_token_secret_version = "projects/${module.project.project_id}/secrets/github-pat/versions/latest"
    }
  }
}

resource "google_cloudbuildv2_repository" "drive_transfer_service_repo" {
  project           = module.project.project_id
  location          = var.default_region
  name              = "drive-transfer-service"
  parent_connection = google_cloudbuildv2_connection.github_host_connection.name
  remote_uri        = "https://github.com/MattDV57/forguide.git"
}

# Cloud Build Triggers
resource "google_cloudbuild_trigger" "api_webhook_trigger" {
  project     = module.project.project_id
  location    = var.default_region
  name        = "drive-transfer-service-api-deploy"
  description = "Webhook trigger invoked by GitHub to deploy API"

  github {
    owner = "MattDV57"
    name  = "forguide"
    push {
      branch = "^main$"
    }
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  included_files = [
    "api/**"
  ]

  build {
<<<<<<< HEAD
    logs_bucket = "gs://${module.cb_logs_bucket.name}/api"
=======
    logs_bucket = "gs://$${_CB_LOGS_BUCKET}/api"
>>>>>>> 99f04a3 (testiong)
    options {
      log_streaming_option = "STREAM_ON"
      logging              = "GCS_ONLY"
    }
<<<<<<< HEAD
=======
    images = [
      "$${_REGION}-docker.pkg.dev/$PROJECT_ID/$${_AR_REGISTRY_NAME}/$${_IMAGE}:$COMMIT_SHA",
      "$${_REGION}-docker.pkg.dev/$PROJECT_ID/$${_AR_REGISTRY_NAME}/$${_IMAGE}:latest"
    ]
>>>>>>> 99f04a3 (testiong)
    step {
      id         = "docker-build"
      name       = "gcr.io/cloud-builders/docker"
      dir        = "$${_REPO_DIR}"
      entrypoint = "sh"
      args = [
        "-xe",
        "-c",
        <<-EOT
        docker build \
        --cache-from $${_REGION}-docker.pkg.dev/$PROJECT_ID/$${_AR_REGISTRY_NAME}/$${_IMAGE}:latest \
        -t=$${_REGION}-docker.pkg.dev/$PROJECT_ID/$${_AR_REGISTRY_NAME}/$${_IMAGE}:$COMMIT_SHA \
        -t=$${_REGION}-docker.pkg.dev/$PROJECT_ID/$${_AR_REGISTRY_NAME}/$${_IMAGE}:latest \
        .
        EOT
      ]
    }
    step {
      id   = "docker-push-sha"
      name = "gcr.io/cloud-builders/docker"
      dir  = "$${_REPO_DIR}"
      args = [
        "push",
        "$${_REGION}-docker.pkg.dev/$PROJECT_ID/$${_AR_REGISTRY_NAME}/$${_IMAGE}:$COMMIT_SHA"
      ]
    }
    step {
      id   = "docker-push-latest"
      name = "gcr.io/cloud-builders/docker"
      dir  = "$${_REPO_DIR}"
      args = [
        "push",
        "$${_REGION}-docker.pkg.dev/$PROJECT_ID/$${_AR_REGISTRY_NAME}/$${_IMAGE}:latest"
      ]
    }
    step {
      id         = "cloud-deploy-release"
      name       = "google/cloud-sdk:slim"
      dir        = "$${_REPO_DIR}"
      entrypoint = "sh"
      args = [
        "-xe",
        "-c",
        <<-EOT
        gcloud config set deploy/region $${_REGION}
        gcloud deploy apply --file cloud_deploy/pipeline.yaml
        gcloud deploy apply --file cloud_deploy/targets.yaml
        gcloud deploy releases create $${_IMAGE}-$$(echo -n $COMMIT_SHA | tail -c 10) \
          --delivery-pipeline=drive-transfer-service \
          --skaffold-version=2.11 \
          --skaffold-file=skaffold.yaml
        EOT
      ]
    }
  }

  substitutions = {
<<<<<<< HEAD
=======
    "_CB_LOGS_BUCKET"   = module.cb_logs_bucket.name
>>>>>>> 99f04a3 (testiong)
    "_AR_REGISTRY_NAME" = "drive-transfer-service"
    "_IMAGE"            = "api"
    "_REGION"           = var.default_region
    "_REPO_DIR"         = "api"
  }

  service_account = module.bootstrap_service_accounts["drive-transfer-service-api"].id
}

resource "google_cloudbuild_trigger" "ui_webhook_trigger" {
  project     = module.project.project_id
  location    = var.default_region
  name        = "drive-transfer-service-ui-deploy"
  description = "Webhook trigger invoked by GitHub to deploy UI"

  github {
    owner = "MattDV57"
    name  = "forguide"
    push {
      branch = "^main$"
    }
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  included_files = [
    "ui/**"
  ]

  build {
<<<<<<< HEAD
    logs_bucket = "gs://${module.cb_logs_bucket.name}/ui"
=======
    logs_bucket = "gs://$${_CB_LOGS_BUCKET}/ui"
>>>>>>> 99f04a3 (testiong)
    options {
      log_streaming_option = "STREAM_ON"
      logging              = "GCS_ONLY"
    }
    step {
      id         = "app-deploy"
      name       = "google/cloud-sdk:slim"
      dir        = "$${_REPO_DIR}"
      entrypoint = "gcloud"
      args = [
        "app",
        "deploy"
      ]
    }
  }

  substitutions = {
<<<<<<< HEAD
    "_REPO_DIR" = "ui"
=======
    "_CB_LOGS_BUCKET" = module.cb_logs_bucket.name
    "_REPO_DIR"       = "ui"
>>>>>>> 99f04a3 (testiong)
  }

  service_account = module.bootstrap_service_accounts["drive-transfer-service-ui"].id
}

resource "google_cloudbuild_trigger" "tf_plan_webhook_triggers" {
  for_each    = toset(var.terraform_environments)
  project     = module.project.project_id
  location    = var.default_region
  name        = "${each.value}-terraform-plan-deploy"
  description = "Webhook trigger invoked by GitHub to run ${each.value} Terraform Plan"

  github {
    owner = "MattDV57"
    name  = "forguide"
    pull_request {
      branch = "^main$"
    }
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  included_files = [
    "terraform/environments/${each.value}/**"
  ]

  build {
<<<<<<< HEAD
    logs_bucket = "gs://${module.cb_logs_bucket.name}/tf/${each.value}/plan"
=======
    logs_bucket = "gs://$${_CB_LOGS_BUCKET}/tf/$${_ENVIRONMENT}/plan"
>>>>>>> 99f04a3 (testiong)
    options {
      log_streaming_option = "STREAM_ON"
      logging              = "GCS_ONLY"
    }
    step {
      id         = "tf-init"
      name       = "$${_REGION}-docker.pkg.dev/$${_AR_PROJECT_ID}/$${_AR_REGISTRY_NAME}/$${_IMAGE}:$${_TERRAFORM_VERSION}"
<<<<<<< HEAD
      dir        = "$${_REPO_DIR}/environments/${each.value}"
=======
      dir        = "$${_REPO_DIR}/environments/$${_ENVIRONMENT}"
>>>>>>> 99f04a3 (testiong)
      entrypoint = "sh"
      args = [
        "-xe",
        "-c",
        <<-EOT
        echo ""
        echo "*************** TERRAFORM INIT ******************"
<<<<<<< HEAD
        echo "******* At environment: ${each.value} *********"
=======
        echo "******* At environment: $${_ENVIRONMENT} *********"
>>>>>>> 99f04a3 (testiong)
        echo "*************************************************"
        terraform init || exit 1
        EOT
      ]
    }
    step {
      id         = "tf-validate"
      name       = "$${_REGION}-docker.pkg.dev/$${_AR_PROJECT_ID}/$${_AR_REGISTRY_NAME}/$${_IMAGE}:$${_TERRAFORM_VERSION}"
<<<<<<< HEAD
      dir        = "$${_REPO_DIR}/environments/${each.value}"
=======
      dir        = "$${_REPO_DIR}/environments/$${_ENVIRONMENT}"
>>>>>>> 99f04a3 (testiong)
      entrypoint = "sh"
      args = [
        "-xe",
        "-c",
        <<-EOT
        echo ""
        echo "*************** TERRAFORM VALIDATE ******************"
<<<<<<< HEAD
        echo "******* At environment: ${each.value} *********"
=======
        echo "******* At environment: $${_ENVIRONMENT} *********"
>>>>>>> 99f04a3 (testiong)
        echo "*************************************************"
        terraform validate || exit 1
        EOT
      ]
    }
    step {
      id         = "tf-plan"
      name       = "$${_REGION}-docker.pkg.dev/$${_AR_PROJECT_ID}/$${_AR_REGISTRY_NAME}/$${_IMAGE}:$${_TERRAFORM_VERSION}"
<<<<<<< HEAD
      dir        = "$${_REPO_DIR}/environments/${each.value}"
=======
      dir        = "$${_REPO_DIR}/environments/$${_ENVIRONMENT}"
>>>>>>> 99f04a3 (testiong)
      entrypoint = "sh"
      args = [
        "-xe",
        "-c",
        <<-EOT
        echo ""
        echo "*************** TERRAFORM PLAN ******************"
<<<<<<< HEAD
        echo "******* At environment: ${each.value} *********"
=======
        echo "******* At environment: $${_ENVIRONMENT} *********"
>>>>>>> 99f04a3 (testiong)
        echo "*************************************************"
        terraform plan -lock=false -input=false || exit 1
        EOT
      ]
    }
  }

  substitutions = {
<<<<<<< HEAD
=======
    "_CB_LOGS_BUCKET"    = module.cb_logs_bucket.name
    "_ENVIRONMENT"       = each.value
>>>>>>> 99f04a3 (testiong)
    "_AR_PROJECT_ID"     = module.project.project_id
    "_AR_REGISTRY_NAME"  = "terraform-cloudbuilder"
    "_IMAGE"             = "terraform"
    "_TERRAFORM_VERSION" = "1.9.5"
    "_REGION"            = var.default_region
    "_REPO_DIR"          = "terraform"
  }

  service_account = module.bootstrap_service_accounts["drive-transfer-service-tf"].id
}

resource "google_cloudbuild_trigger" "tf_apply_webhook_triggers" {
  for_each    = toset(var.terraform_environments)
  project     = module.project.project_id
  location    = var.default_region
  name        = "${each.value}-terraform-apply-deploy"
  description = "Webhook trigger invoked by GitHub to run ${each.value} Terraform Apply"

  github {
    owner = "MattDV57"
    name  = "forguide"
    push {
      branch = "^main$"
    }
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  included_files = [
    "terraform/environments/${each.value}/**"
  ]

  build {
    timeout     = "1200s"
<<<<<<< HEAD
    logs_bucket = "gs://${module.cb_logs_bucket.name}/tf/${each.value}/apply"
    artifacts {
      objects {
        location = "gs://${module.cb_artifacts_bucket.name}/tf/${each.value}/$BUILD_ID"
        paths = [
          "/workspace/$${_REPO_DIR}/environments/${each.value}/*.plan"
=======
    logs_bucket = "gs://$${_CB_LOGS_BUCKET}/tf/$${_ENVIRONMENT}/apply"
    artifacts {
      objects {
        location = "gs://$${_CB_ARTIFACTS_BUCKET}/tf/$${_ENVIRONMENT}/$BUILD_ID"
        paths = [
          "/workspace/$${_REPO_DIR}/environments/$${_ENVIRONMENT}/*.plan"
>>>>>>> 99f04a3 (testiong)
        ]
      }
    }
    options {
      log_streaming_option = "STREAM_ON"
      logging              = "GCS_ONLY"
    }
    step {
      id         = "tf-init"
      name       = "$${_REGION}-docker.pkg.dev/$${_AR_PROJECT_ID}/$${_AR_REGISTRY_NAME}/$${_IMAGE}:$${_TERRAFORM_VERSION}"
<<<<<<< HEAD
      dir        = "$${_REPO_DIR}/environments/${each.value}"
=======
      dir        = "$${_REPO_DIR}/environments/$${_ENVIRONMENT}"
>>>>>>> 99f04a3 (testiong)
      entrypoint = "sh"
      args = [
        "-xe",
        "-c",
        <<-EOT
        echo ""
        echo "*************** TERRAFORM INIT ******************"
<<<<<<< HEAD
        echo "******* At environment: ${each.value} *********"
=======
        echo "******* At environment: $${_ENVIRONMENT} *********"
>>>>>>> 99f04a3 (testiong)
        echo "*************************************************"
        terraform init || exit 1
        EOT
      ]
    }
    step {
      id         = "tf-validate"
      name       = "$${_REGION}-docker.pkg.dev/$${_AR_PROJECT_ID}/$${_AR_REGISTRY_NAME}/$${_IMAGE}:$${_TERRAFORM_VERSION}"
<<<<<<< HEAD
      dir        = "$${_REPO_DIR}/environments/${each.value}"
=======
      dir        = "$${_REPO_DIR}/environments/$${_ENVIRONMENT}"
>>>>>>> 99f04a3 (testiong)
      entrypoint = "sh"
      args = [
        "-xe",
        "-c",
        <<-EOT
        echo ""
        echo "*************** TERRAFORM VALIDATE ******************"
<<<<<<< HEAD
        echo "******* At environment: ${each.value} *********"
=======
        echo "******* At environment: $${_ENVIRONMENT} *********"
>>>>>>> 99f04a3 (testiong)
        echo "*************************************************"
        terraform validate || exit 1
        EOT
      ]
    }
    step {
      id         = "tf-plan"
      name       = "$${_REGION}-docker.pkg.dev/$${_AR_PROJECT_ID}/$${_AR_REGISTRY_NAME}/$${_IMAGE}:$${_TERRAFORM_VERSION}"
<<<<<<< HEAD
      dir        = "$${_REPO_DIR}/environments/${each.value}"
=======
      dir        = "$${_REPO_DIR}/environments/$${_ENVIRONMENT}"
>>>>>>> 99f04a3 (testiong)
      entrypoint = "sh"
      args = [
        "-xe",
        "-c",
        <<-EOT
        echo ""
        echo "*************** TERRAFORM PLAN ******************"
<<<<<<< HEAD
        echo "******* At environment: ${each.value} *********"
        echo "*************************************************"
        terraform plan -input=false -out="/workspace/$${_REPO_DIR}/environments/${each.value}/$${BUILD_ID}_tfplan.plan" || exit 1
=======
        echo "******* At environment: $${_ENVIRONMENT} *********"
        echo "*************************************************"
        terraform plan -input=false -out="/workspace/$${_REPO_DIR}/environments/$${_ENVIRONMENT}/$${BUILD_ID}_tfplan.plan" || exit 1
>>>>>>> 99f04a3 (testiong)
        EOT
      ]
    }
    step {
      id         = "tf-apply"
      name       = "$${_REGION}-docker.pkg.dev/$${_AR_PROJECT_ID}/$${_AR_REGISTRY_NAME}/$${_IMAGE}:$${_TERRAFORM_VERSION}"
<<<<<<< HEAD
      dir        = "$${_REPO_DIR}/environments/${each.value}"
=======
      dir        = "$${_REPO_DIR}/environments/$${_ENVIRONMENT}"
>>>>>>> 99f04a3 (testiong)
      entrypoint = "sh"
      args = [
        "-xe",
        "-c",
        <<-EOT
        echo ""
        echo "*************** TERRAFORM APPLY ******************"
<<<<<<< HEAD
        echo "******* At environment: ${each.value} *********"
        echo "*************************************************"
        terraform apply -auto-approve -input=false "/workspace/$${_REPO_DIR}/environments/${each.value}/$${BUILD_ID}_tfplan.plan" || exit 1
=======
        echo "******* At environment: $${_ENVIRONMENT} *********"
        echo "*************************************************"
        terraform apply -auto-approve -input=false "/workspace/$${_REPO_DIR}/environments/$${_ENVIRONMENT}/$${BUILD_ID}_tfplan.plan" || exit 1
>>>>>>> 99f04a3 (testiong)
        EOT
      ]
    }
  }

  substitutions = {
<<<<<<< HEAD
    "_AR_PROJECT_ID"     = module.project.project_id
    "_AR_REGISTRY_NAME"  = "terraform-cloudbuilder"
    "_IMAGE"             = "terraform"
    "_TERRAFORM_VERSION" = "1.9.5"
    "_REGION"            = var.default_region
    "_REPO_DIR"          = "terraform"
=======
    "_CB_LOGS_BUCKET"      = module.cb_logs_bucket.name
    "_ENVIRONMENT"         = each.value
    "_CB_ARTIFACTS_BUCKET" = module.cb_artifacts_bucket.name
    "_AR_PROJECT_ID"       = module.project.project_id
    "_AR_REGISTRY_NAME"    = "terraform-cloudbuilder"
    "_IMAGE"               = "terraform"
    "_TERRAFORM_VERSION"   = "1.9.5"
    "_REGION"              = var.default_region
    "_REPO_DIR"            = "terraform"
>>>>>>> 99f04a3 (testiong)
  }

  service_account = module.bootstrap_service_accounts["drive-transfer-service-tf"].id
}

# Manual Container Build Triggers
resource "google_cloudbuild_trigger" "terraform_builder_trigger" {
  project     = module.project.project_id
  location    = var.default_region
  name        = "terraform-builder-deploy"
  description = "Manually invoked trigger to build Terraform Builder image"

  github {
    owner = "MattDV57"
    name  = "forguide"
    push {
      branch = "^main$"
    }
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  included_files = [
    "terraform/modules/terraform-cloudbuilder/**"
  ]

  build {
<<<<<<< HEAD
    logs_bucket = "gs://${module.cb_logs_bucket.name}/terraform-builder"
=======
    logs_bucket = "gs://$${_CB_LOGS_BUCKET}/terraform-builder"
>>>>>>> 99f04a3 (testiong)
    options {
      log_streaming_option = "STREAM_ON"
      logging              = "GCS_ONLY"
    }
<<<<<<< HEAD
=======
    images = [
      "$${_REGION}-docker.pkg.dev/$PROJECT_ID/$${_AR_REGISTRY_NAME}/$${_IMAGE}:$${_TF_VERSION}"
    ]
>>>>>>> 99f04a3 (testiong)
    step {
      id         = "docker-build"
      name       = "gcr.io/cloud-builders/docker"
      dir        = "$${_REPO_DIR}"
      entrypoint = "sh"
      args = [
        "-xe",
        "-c",
        <<-EOT
        docker build \
        -t=$${_REGION}-docker.pkg.dev/$PROJECT_ID/$${_AR_REGISTRY_NAME}/$${_IMAGE}:$${_TF_VERSION} \
        .
        EOT
      ]
    }
<<<<<<< HEAD
    step {
      id   = "docker-push"
      name = "gcr.io/cloud-builders/docker"
      dir  = "$${_REPO_DIR}"
      args = [
        "push",
        "$${_REGION}-docker.pkg.dev/$PROJECT_ID/$${_AR_REGISTRY_NAME}/$${_IMAGE}:$${_TF_VERSION}"
      ]
    }
  }

  substitutions = {
=======
  }

  substitutions = {
    "_CB_LOGS_BUCKET"   = module.cb_logs_bucket.name
>>>>>>> 99f04a3 (testiong)
    "_AR_REGISTRY_NAME" = "terraform-cloudbuilder"
    "_IMAGE"            = "terraform"
    "_TF_VERSION"       = "1.9.5"
    "_REGION"           = var.default_region
    "_REPO_DIR"         = "terraform/modules/terraform-cloudbuilder"
  }

  service_account = module.bootstrap_service_accounts["container-builder"].id
}

resource "google_cloudbuild_trigger" "gcs_fuse_trigger" {
  project     = module.project.project_id
  location    = var.default_region
  name        = "gcs-fuse-sidecar-deploy"
  description = "Manually invoked trigger to build GCS Fuse Sidecar image"

  github {
    owner = "MattDV57"
    name  = "forguide"
    push {
      branch = "^main$"
    }
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"

  included_files = [
    "terraform/modules/gcs-fuse/**"
  ]

  build {
<<<<<<< HEAD
    logs_bucket = "gs://${module.cb_logs_bucket.name}/gcs-fuse"
=======
    logs_bucket = "gs://$${_CB_LOGS_BUCKET}/gcs-fuse"
>>>>>>> 99f04a3 (testiong)
    options {
      log_streaming_option = "STREAM_ON"
      logging              = "GCS_ONLY"
    }
<<<<<<< HEAD
=======
    images = [
      "$${_REGION}-docker.pkg.dev/$PROJECT_ID/$${_AR_REGISTRY_NAME}/$${_IMAGE}:latest"
    ]
>>>>>>> 99f04a3 (testiong)
    step {
      id         = "docker-pull"
      name       = "gcr.io/cloud-builders/docker"
      entrypoint = "sh"
      args = [
        "-xe",
        "-c",
        <<-EOT
        docker pull \
        gcr.io/gke-release/gcs-fuse-csi-driver-sidecar-mounter@sha256:$${_GCS_FUSE_VERSION_SHA}
        EOT
      ]
    }
    step {
      id         = "docker-tag"
      name       = "gcr.io/cloud-builders/docker"
      entrypoint = "sh"
      args = [
        "-xe",
        "-c",
        <<-EOT
        docker tag \
        gcr.io/gke-release/gcs-fuse-csi-driver-sidecar-mounter@sha256:$${_GCS_FUSE_VERSION_SHA} \
        $${_REGION}-docker.pkg.dev/$PROJECT_ID/$${_AR_REGISTRY_NAME}/$${_IMAGE}:latest
        EOT
      ]
    }
<<<<<<< HEAD
    step {
      id   = "docker-push-latest"
      name = "gcr.io/cloud-builders/docker"
      dir  = "$${_REPO_DIR}"
      args = [
        "push",
        "$${_REGION}-docker.pkg.dev/$PROJECT_ID/$${_AR_REGISTRY_NAME}/$${_IMAGE}:latest"
      ]
    }
  }

  substitutions = {
=======
  }

  substitutions = {
    "_CB_LOGS_BUCKET"   = module.cb_logs_bucket.name
>>>>>>> 99f04a3 (testiong)
    "_AR_REGISTRY_NAME" = "drive-transfer-service"
    "_IMAGE"            = "gcs-fuse-csi-driver-sidecar-mounter"
    # IMPORTANT: THIS SHA VALUE SHOULD CHANGE ACCORDING TO GKE VERSION 
    # (https://github.com/GoogleCloudPlatform/gcs-fuse-csi-driver/blob/main/docs/releases.md#gke-compatibility)
    "_GCS_FUSE_VERSION_SHA" = "a527a083127fb456c96a6e4a478639222065dc0c2d485729e63605035d624f8f"
    "_REGION"               = var.default_region
  }

  service_account = module.bootstrap_service_accounts["container-builder"].id
<<<<<<< HEAD
}
=======
}
>>>>>>> 99f04a3 (testiong)
