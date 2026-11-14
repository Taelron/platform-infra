# Component of every taggable resource in this file (OpenTofu on AWS,
# pattern 5); merged with the provider's default tags.
locals {
  cognito_tags = { Component = "sign-in" }
}

# The site's own user pool, separate from the platform's. Readers sign in with
# their AWS login through IAM Identity Center (below); the pool keeps no local
# accounts and only hands the edge functions their tokens. Its own settings
# (email, MFA) apply only to local accounts, of which there are none.
resource "aws_cognito_user_pool" "readers" {
  tags = local.cognito_tags

  name                = "docs-readers"
  deletion_protection = "ACTIVE"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  mfa_configuration = "ON"

  software_token_mfa_configuration {
    enabled = true
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  username_configuration {
    case_sensitive = false
  }
}

# Cognito's own sign-in domain: <prefix>.auth.eu-central-1.amazoncognito.com.
resource "aws_cognito_user_pool_domain" "readers" {
  domain                = "taelron-docs"
  user_pool_id          = aws_cognito_user_pool.readers.id
  managed_login_version = 1
}

# IAM Identity Center (management account, eu-central-1) is the only sign-in.
# Its side is the customer managed SAML 2.0 application "Taelron Docs", which
# AWS lets you create in the console only (README.md, "Sign-in"): who is
# assigned to it reads the docs, and Identity Center applies its own MFA.
locals {
  identity_center_provider     = "IdentityCenter"
  identity_center_metadata_url = "https://portal.sso.eu-central-1.amazonaws.com/saml/metadata/MzEwNjY2ODg4MzUxX2lucy02OTg3NjQ5N2VjZDg4NzVm"

  # Cognito puts every user who signs in through a provider in this group.
  reader_group = "${aws_cognito_user_pool.readers.id}_${local.identity_center_provider}"
}

resource "aws_cognito_identity_provider" "identity_center" {
  user_pool_id  = aws_cognito_user_pool.readers.id
  provider_name = local.identity_center_provider
  provider_type = "SAML"

  provider_details = {
    MetadataURL = local.identity_center_metadata_url
    IDPSignout  = "false"
  }

  attribute_mapping = {
    email = "email"
  }

  # Read back from the metadata by Cognito, not set here.
  lifecycle {
    ignore_changes = [
      provider_details["ActiveEncryptionCertificate"],
      provider_details["SLORedirectBindingURI"],
      provider_details["SSORedirectBindingURI"],
    ]
  }
}

# Public client: the edge functions keep no client secret and sign in with the
# authorization code and PKCE.
resource "aws_cognito_user_pool_client" "site" {
  name         = "docs-site"
  user_pool_id = aws_cognito_user_pool.readers.id

  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = local.edge_oauth_scopes
  supported_identity_providers         = [aws_cognito_identity_provider.identity_center.provider_name]
  callback_urls                        = ["https://${local.domain_name}${local.edge_paths.sign_in}"]
  logout_urls                          = ["https://${local.domain_name}${local.edge_paths.after_sign_out}"]
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true
}
