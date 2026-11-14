# Signs in as the GitHub App taelron-platform-admin, installed on the two
# platform repositories only. Each run gets a one-hour installation token; the
# private key is read from pass at run time (see README.md).
provider "github" {
  owner = "Taelron"

  app_auth {
    id              = 5753270   # taelron-platform-admin
    installation_id = 181784345 # Taelron, platform-infra and platform-gitops
    pem_file        = var.github_app_private_key
  }
}

variable "github_app_private_key" {
  description = "Private key of the GitHub App taelron-platform-admin. Read from pass at run time."
  type        = string
  sensitive   = true
}

locals {
  repositories = toset(["platform-infra", "platform-gitops"])

  # GitHub user id of Gaetan-Jaminon, the only approver of an apply.
  approver_user_id = 177243329
}
