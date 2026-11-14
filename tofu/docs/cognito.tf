# The site's own user pool, separate from the platform's: readers sign in with
# their email and an authenticator app; Gaetan creates every account.
resource "aws_cognito_user_pool" "readers" {
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

# One group: its members read every page. A signed-in account without it sees
# only the access-denied page.
resource "aws_cognito_user_group" "reader" {
  name         = "docs-reader"
  description  = "Reads all of Taelron Docs"
  user_pool_id = aws_cognito_user_pool.readers.id
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
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = ["https://${local.domain_name}${local.edge_paths.sign_in}"]
  logout_urls                          = ["https://${local.domain_name}${local.edge_paths.after_sign_out}"]
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true
}
