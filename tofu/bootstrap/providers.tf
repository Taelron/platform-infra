provider "aws" {
  region              = "eu-central-1"
  allowed_account_ids = [local.account_id]

  default_tags {
    tags = {
      Project    = "taelron-platform"
      ManagedBy  = "opentofu"
      Repository = "platform-infra"
    }
  }
}

locals {
  account_id = "181841605684" # taelron-platform
  repository = "Taelron/platform-infra"

  # The repository uses GitHub's immutable subject claims: owner and
  # repository carry their numeric IDs, so a renamed or recreated repository
  # with the same name cannot assume the roles.
  oidc_subject_prefix = "repo:Taelron@279244988/platform-infra@1456341560"
}
