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
  account_id  = "181841605684" # taelron-platform
  alert_email = "aws@taelron.com"
}

# us-east-1, only for what CloudFront requires there: the certificate of the
# Cognito login domain sso.taelron.com.
provider "aws" {
  alias               = "us_east_1"
  region              = "us-east-1"
  allowed_account_ids = [local.account_id]

  default_tags {
    tags = {
      Project    = "taelron-platform"
      ManagedBy  = "opentofu"
      Repository = "platform-infra"
    }
  }
}
