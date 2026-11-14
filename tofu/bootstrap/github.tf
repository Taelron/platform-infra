# GitHub Actions signs in to AWS with OIDC: no access key is stored in GitHub.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# --- Plan role: read-only, for `tofu plan` on pull requests -----------------

data "aws_iam_policy_document" "plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.repository}:pull_request"]
    }
  }
}

resource "aws_iam_role" "plan" {
  name                 = "platform-github-plan"
  description          = "GitHub Actions, tofu plan on pull requests in ${local.repository} (read-only)"
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "plan_read_only" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# A plan takes the state lock: it writes and deletes the .tflock object only.
data "aws_iam_policy_document" "plan_state_lock" {
  statement {
    sid       = "StateLockObjects"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/platform/*.tflock"]
  }
}

resource "aws_iam_role_policy" "plan_state_lock" {
  name   = "state-lock"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_state_lock.json
}

# Any pull request can run code with this role, so ReadOnlyAccess is cut back
# to metadata: no object or secret contents except the platform state. The
# bootstrap state holds the Red Hat external ID; the backup buckets hold data.
data "aws_iam_policy_document" "plan_guard" {
  statement {
    sid           = "DenyObjectReadsOutsidePlatformState"
    effect        = "Deny"
    actions       = ["s3:GetObject", "s3:GetObjectVersion"]
    not_resources = ["${aws_s3_bucket.state.arn}/platform/*"]
  }

  statement {
    sid    = "DenySecretValues"
    effect = "Deny"
    actions = [
      "secretsmanager:GetSecretValue",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:GetParameterHistory",
      "kms:Decrypt",
    ]
    resources = ["*"]
  }

  # The Red Hat role's trust policy carries the external ID; the plan of the
  # platform root never needs it.
  statement {
    sid       = "DenyRedHatRoleRead"
    effect    = "Deny"
    actions   = ["iam:GetRole"]
    resources = [aws_iam_role.redhat_cloud_access.arn]
  }

  statement {
    sid       = "DenyAccountIamDump"
    effect    = "Deny"
    actions   = ["iam:GetAccountAuthorizationDetails"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "plan_guard" {
  name   = "plan-guard"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_guard.json
}

# --- Apply role: `tofu apply` on main, behind the environment "production" ---
#
# The token's subject names the environment. The environment accepts
# deployments from main only and waits for Gaetan's approval, so this role is
# reachable only from main after that approval.

data "aws_iam_policy_document" "apply_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.repository}:environment:production"]
    }
  }
}

resource "aws_iam_role" "apply" {
  name                 = "platform-github-apply"
  description          = "GitHub Actions, tofu apply on main in ${local.repository}, environment production"
  assume_role_policy   = data.aws_iam_policy_document.apply_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "apply_admin" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# The bootstrap is applied from the RHEL box only: the pipeline cannot change
# its own roles, the OIDC provider, or the state bucket's settings.
data "aws_iam_policy_document" "apply_guard" {
  statement {
    sid    = "DenyBootstrapIam"
    effect = "Deny"
    not_actions = [
      "iam:Get*",
      "iam:List*",
    ]
    resources = [
      aws_iam_role.plan.arn,
      aws_iam_role.apply.arn,
      aws_iam_openid_connect_provider.github.arn,
      aws_iam_role.redhat_cloud_access.arn,
      aws_iam_policy.redhat_cloud_access.arn,
    ]
  }

  # No long-lived credentials, ever: no IAM users, access keys or passwords.
  statement {
    sid    = "DenyLongLivedCredentials"
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:CreateAccessKey",
      "iam:CreateLoginProfile",
      "iam:UpdateLoginProfile",
      "iam:CreateServiceSpecificCredential",
      "iam:UploadSSHPublicKey",
      "iam:UploadSigningCertificate",
      "iam:CreateVirtualMFADevice",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyStateBucketSettings"
    effect = "Deny"
    actions = [
      "s3:DeleteBucket",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketOwnershipControls",
      "s3:PutLifecycleConfiguration",
    ]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid    = "DenyBootstrapState"
    effect = "Deny"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:PutObjectAcl",
    ]
    resources = ["${aws_s3_bucket.state.arn}/bootstrap/*"]
  }
}

resource "aws_iam_role_policy" "apply_guard" {
  name   = "bootstrap-guard"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply_guard.json
}
