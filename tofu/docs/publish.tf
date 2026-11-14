# The publish workflow of Taelron/taelron-docs-site copies the pages to the
# bucket and invalidates the distribution (TAE-155). It signs in with GitHub
# OIDC, from main of that repository only: no stored key.

locals {
  # The provider is created and owned by tofu/bootstrap; built from its fixed
  # ARN so that the plan role needs no read on it.
  github_oidc_provider_arn = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"

  # The repository uses GitHub's immutable subject (owner and repository
  # carry their numeric IDs): a renamed or recreated repository cannot sign in.
  publish_subject = "repo:Taelron@279244988/taelron-docs-site@1457353416:ref:refs/heads/main"
}

data "aws_iam_policy_document" "publish_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.publish_subject]
    }
  }
}

resource "aws_iam_role" "publish" {
  name                 = "docs-publish"
  description          = "GitHub Actions, publish workflow of Taelron/taelron-docs-site on main"
  assume_role_policy   = data.aws_iam_policy_document.publish_trust.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "publish" {
  statement {
    sid       = "ListSite"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn]
  }

  statement {
    sid       = "WritePages"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }

  statement {
    sid       = "Invalidate"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_role_policy" "publish" {
  name   = "publish"
  role   = aws_iam_role.publish.id
  policy = data.aws_iam_policy_document.publish.json
}
