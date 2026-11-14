# Sign-in for the platform UIs (Platform Design Decisions, 4 and 5): an Amazon
# Cognito user pool (OIDC), login by email, MFA required, its login page on
# sso.taelron.com. Gaetan creates every account; clients get read-only roles
# through the group "viewers".

locals {
  # Inventory grouping (TAE-156): every taggable resource of this file.
  sign_in_tags = { Component = "sign-in" }

  sso_domain = "sso.taelron.com"
}

resource "aws_cognito_user_pool" "platform" {
  name                = "platform-users"
  username_attributes = ["email"]
  deletion_protection = "ACTIVE"

  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  # Accounts are created by Gaetan only, and disabled when a trial ends.
  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  mfa_configuration = "ON"

  software_token_mfa_configuration {
    enabled = true
  }

  password_policy {
    minimum_length                   = 14
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 3
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = local.sign_in_tags
}

resource "aws_cognito_user_group" "platform" {
  for_each = {
    platform-admins = "Full access to the platform UIs"
    viewers         = "Read-only access to the platform UIs, for clients"
  }

  user_pool_id = aws_cognito_user_pool.platform.id
  name         = each.key
  description  = each.value
}

# The login domain's certificate: CloudFront serves the Cognito login page,
# so it lives in us-east-1. Validated by a record Gaetan enters in Microsoft
# 365 (output m365_sso_certificate_validation).
resource "aws_acm_certificate" "sso" {
  provider = aws.us_east_1

  domain_name       = local.sso_domain
  validation_method = "DNS"

  tags = merge(local.sign_in_tags, {
    Name = "platform-sso"
  })

  lifecycle {
    create_before_destroy = true
  }
}
