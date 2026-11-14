# Component of every taggable resource in this file (OpenTofu on AWS,
# pattern 5); merged with the provider's default tags.
locals {
  github_tags = { Component = "pipeline" }
}

# GitHub Actions signs in to AWS with OIDC: no access key is stored in GitHub.
resource "aws_iam_openid_connect_provider" "github" {
  tags = local.github_tags

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
      values   = ["${local.oidc_subject_prefix}:pull_request"]
    }
  }
}

resource "aws_iam_role" "plan" {
  tags = local.github_tags

  name                 = "platform-github-plan"
  description          = "GitHub Actions, tofu plan on pull requests in ${local.repository} (read-only)"
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = 3600
}

# What `tofu plan` of tofu/platform and tofu/docs reads, and nothing else. Any pull request
# can run code with this role, so it gets an allowlist instead of
# ReadOnlyAccess, which also reads data (logs, items, code, trust policies).
# The services are those of the Platform Runbook, Phase 3, and of Taelron Docs
# (TAE-146); a pull request that brings a new service adds its read actions
# here, applied from the RHEL box.
data "aws_iam_policy_document" "plan_read" {
  statement {
    sid     = "PipelineState"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.state.arn}/platform/*",
      "${aws_s3_bucket.state.arn}/docs/*",
    ]
  }

  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  # Network, instance, volumes, AMI lookup, load balancer, certificates.
  statement {
    sid = "Describe"
    actions = [
      "ec2:Describe*",
      "ec2:GetEbsDefaultKmsKeyId",
      "ec2:GetEbsEncryptionByDefault",
      "elasticloadbalancing:Describe*",
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate",
      "dlm:GetLifecyclePolicies",
      "dlm:GetLifecyclePolicy",
      "dlm:ListTagsForResource",
      "scheduler:GetSchedule",
      "scheduler:GetScheduleGroup",
      "scheduler:ListSchedules",
      "scheduler:ListScheduleGroups",
      "scheduler:ListTagsForResource",
      "budgets:ViewBudget",
      "budgets:ListTagsForResource",
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListAliases",
      "kms:ListResourceTags",
    ]
    resources = ["*"]
  }

  # Taelron Docs: the distribution, its origin access control and the managed
  # cache policies it uses.
  statement {
    sid = "CloudFront"
    actions = [
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:GetCachePolicy",
      "cloudfront:ListCachePolicies",
      "cloudfront:ListTagsForResource",
    ]
    resources = ["*"]
  }

  # Taelron Docs: the Lambda@Edge functions. GetFunction also returns a link
  # to the code, which holds the nonce signing secret of the sign-in redirect;
  # accepted, as for the Cognito app client below.
  statement {
    sid = "DocsLambda"
    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:ListVersionsByFunction",
      "lambda:ListTags",
    ]
    resources = ["arn:aws:lambda:us-east-1:${local.account_id}:function:docs-*"]
  }

  # Cognito: reading an app client returns its secret, which the platform
  # state holds anyway. Accepted: both are readable by the plan of main.
  statement {
    sid = "Cognito"
    actions = [
      "cognito-idp:DescribeUserPool",
      "cognito-idp:DescribeUserPoolClient",
      "cognito-idp:DescribeIdentityProvider",
      "cognito-idp:DescribeUserPoolDomain",
      "cognito-idp:GetGroup",
      "cognito-idp:GetUserPoolMfaConfig",
      "cognito-idp:GetUICustomization",
      "cognito-idp:GetLogDeliveryConfiguration",
      "cognito-idp:ListGroups",
      "cognito-idp:ListUserPoolClients",
      "cognito-idp:ListTagsForResource",
    ]
    resources = ["*"]
  }

  # IAM, only for the platform's and Taelron Docs' own names: never the
  # bootstrap's Red Hat role.
  statement {
    sid = "PlatformIam"
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListRoleTags",
      "iam:ListInstanceProfilesForRole",
      "iam:GetInstanceProfile",
      "iam:ListInstanceProfileTags",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:ListPolicyTags",
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/platform-*",
      "arn:aws:iam::${local.account_id}:role/docs-*",
      "arn:aws:iam::${local.account_id}:instance-profile/platform-*",
      "arn:aws:iam::${local.account_id}:policy/platform-*",
      "arn:aws:iam::aws:policy/*",
    ]
  }

  # Bucket settings, not contents, of the platform's and Taelron Docs' buckets.
  # ListBucket is what HeadBucket needs to read a bucket; it lists keys, never
  # contents.
  statement {
    sid = "PlatformBucketSettings"
    actions = [
      "s3:ListBucket",
      "s3:GetBucket*",
      "s3:GetAccelerateConfiguration",
      "s3:GetEncryptionConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
    ]
    resources = [
      "arn:aws:s3:::platform-*",
      "arn:aws:s3:::docs-*",
    ]
  }
}

resource "aws_iam_role_policy" "plan_read" {
  name   = "plan-read"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_read.json
}

# A plan takes the state lock: it writes and deletes the .tflock object only.
data "aws_iam_policy_document" "plan_state_lock" {
  statement {
    sid     = "StateLockObjects"
    actions = ["s3:PutObject", "s3:DeleteObject"]
    resources = [
      "${aws_s3_bucket.state.arn}/platform/*.tflock",
      "${aws_s3_bucket.state.arn}/docs/*.tflock",
    ]
  }
}

resource "aws_iam_role_policy" "plan_state_lock" {
  name   = "state-lock"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_state_lock.json
}

# Kept behind the allowlist, so that a read added to it later cannot reach
# object or secret contents outside the pipeline's states. The bootstrap state
# and the Red Hat role hold the external ID; the backup buckets hold data.
data "aws_iam_policy_document" "plan_guard" {
  statement {
    sid     = "DenyObjectReadsOutsidePipelineState"
    effect  = "Deny"
    actions = ["s3:GetObject", "s3:GetObjectVersion"]
    not_resources = [
      "${aws_s3_bucket.state.arn}/platform/*",
      "${aws_s3_bucket.state.arn}/docs/*",
    ]
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

# --- Apply role: `tofu apply` on main, behind the environment "aws-apply" ----
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
      values   = ["${local.oidc_subject_prefix}:environment:aws-apply"]
    }
  }
}

resource "aws_iam_role" "apply" {
  tags = local.github_tags

  name                 = "platform-github-apply"
  description          = "GitHub Actions, tofu apply on main in ${local.repository}, environment aws-apply"
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
    # The bootstrap and github roots are applied from the RHEL box only.
    resources = [
      "${aws_s3_bucket.state.arn}/bootstrap/*",
      "${aws_s3_bucket.state.arn}/github/*",
    ]
  }
}

resource "aws_iam_role_policy" "apply_guard" {
  name   = "bootstrap-guard"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply_guard.json
}
