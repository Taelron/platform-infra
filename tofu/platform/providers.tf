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
}
