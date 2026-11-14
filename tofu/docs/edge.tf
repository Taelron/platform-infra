# Lambda@Edge, from aws-samples/cloudfront-authorization-at-edge (edge/),
# extended so that check-auth matches the reader's Cognito groups against the
# space in the path. The bundles in edge/dist are built from edge/src and
# committed; the pipeline checks that they match the source.
#
# Lambda@Edge takes no environment variables: each function reads its
# configuration from configuration.json, zipped next to its bundle.

locals {
  edge_paths = {
    sign_in        = "/parseauth"
    refresh        = "/refreshauth"
    sign_out       = "/signout"
    after_sign_out = "/"
  }

  edge_oauth_scopes = ["openid", "email"]

  # Set on every response by the origin-response function http-headers.
  edge_http_headers = {
    "Content-Security-Policy"   = "default-src 'self'; img-src 'self' data:; font-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'"
    "Strict-Transport-Security" = "max-age=31536000; includeSubDomains"
    "Referrer-Policy"           = "same-origin"
    "X-Frame-Options"           = "DENY"
    "X-Content-Type-Options"    = "nosniff"
  }

  edge_log_level = "warn"

  edge_auth_config = {
    userPoolArn             = aws_cognito_user_pool.readers.arn
    clientId                = aws_cognito_user_pool_client.site.id
    clientSecret            = ""
    oauthScopes             = local.edge_oauth_scopes
    cognitoAuthDomain       = "${aws_cognito_user_pool_domain.readers.domain}.auth.eu-central-1.amazoncognito.com"
    redirectPathSignIn      = local.edge_paths.sign_in
    redirectPathSignOut     = local.edge_paths.after_sign_out
    signOutUrl              = local.edge_paths.sign_out
    redirectPathAuthRefresh = local.edge_paths.refresh
    cookieSettings          = {}
    mode                    = "staticSiteMode"
    httpHeaders             = local.edge_http_headers
    logLevel                = local.edge_log_level
    nonceSigningSecret      = random_password.nonce_signing.result
    cookieCompatibility     = "amplify"
    additionalCookies       = {}
    requiredGroup           = ""
  }

  # Function name suffix => configuration it reads.
  edge_functions = {
    check-auth   = local.edge_auth_config
    parse-auth   = local.edge_auth_config
    refresh-auth = local.edge_auth_config
    sign-out     = local.edge_auth_config
    http-headers = {
      httpHeaders = local.edge_http_headers
      logLevel    = local.edge_log_level
    }
  }
}

# Signs the nonce of the sign-in redirect (CSRF protection). It ends up in the
# function code, which the plan role can read: a pull request author could
# forge a sign-in nonce, never a token.
resource "random_password" "nonce_signing" {
  length  = 32
  special = false
}

data "aws_iam_policy_document" "edge_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "edge" {
  name               = "docs-edge"
  description        = "Lambda@Edge functions of Taelron Docs"
  assume_role_policy = data.aws_iam_policy_document.edge_trust.json
}

resource "aws_iam_role_policy_attachment" "edge_logs" {
  role       = aws_iam_role.edge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "edge" {
  for_each = local.edge_functions

  type        = "zip"
  output_path = "${path.module}/.build/${each.key}.zip"

  source {
    filename = "index.js"
    content  = file("${path.module}/edge/dist/${each.key}.js")
  }

  source {
    filename = "configuration.json"
    content  = jsonencode(each.value)
  }
}

resource "aws_lambda_function" "edge" {
  for_each = local.edge_functions
  provider = aws.us_east_1

  function_name    = "docs-${each.key}"
  role             = aws_iam_role.edge.arn
  runtime          = "nodejs22.x"
  handler          = "index.handler"
  filename         = data.archive_file.edge[each.key].output_path
  source_code_hash = data.archive_file.edge[each.key].output_base64sha256
  memory_size      = 128
  timeout          = 5
  publish          = true
}
