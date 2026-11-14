locals {
  account_id = "181841605684" # taelron-platform

  default_tags = {
    Project    = "taelron-docs"
    ManagedBy  = "opentofu"
    Repository = "platform-infra"
  }

  domain_name = "docs.taelron.com"
}

provider "aws" {
  region              = "eu-central-1"
  allowed_account_ids = [local.account_id]

  default_tags {
    tags = local.default_tags
  }
}

# CloudFront takes its certificate and its Lambda@Edge functions from
# us-east-1 only.
provider "aws" {
  alias               = "us_east_1"
  region              = "us-east-1"
  allowed_account_ids = [local.account_id]

  default_tags {
    tags = local.default_tags
  }
}
