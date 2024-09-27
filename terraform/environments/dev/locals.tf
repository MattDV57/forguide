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

locals {
  sa_config     = yamldecode(file("./assets/sa.yaml"))
  secret_config = yamldecode(file("./assets/secrets.yaml"))
  iam_config    = yamldecode(file("./assets/iam.yaml"))

<<<<<<< HEAD
  service_accounts          = try(local.sa_config.service_accounts, {})
  secrets                   = try(local.secret_config.secrets, {})
  project_iam_bindings      = try(local.iam_config.project_iam.bindings, {})
}
=======
  service_accounts     = try(local.sa_config.service_accounts, {})
  secrets              = try(local.secret_config.secrets, {})
  project_iam_bindings = try(local.iam_config.project_iam.bindings, {})
}
>>>>>>> 99f04a3 (testiong)
