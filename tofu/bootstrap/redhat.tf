# Component of every taggable resource in this file (OpenTofu on AWS,
# pattern 5); merged with the provider's default tags.
locals {
  redhat_tags = { Component = "cloud-access" }
}

# Red Hat Cloud Access: lets Red Hat (cloudigrade) share the RHEL gold images
# with this account. Created by hand in Phase 1, imported here. The role ARN is
# registered in the Red Hat Hybrid Cloud Console, so it is never recreated.

variable "redhat_cloud_access_external_id" {
  description = "External ID Red Hat presents when it assumes the role. Read from pass at run time."
  type        = string
  sensitive   = true
}

import {
  to = aws_iam_policy.redhat_cloud_access
  id = "arn:aws:iam::181841605684:policy/RedHatCloudAccess"
}

import {
  to = aws_iam_role.redhat_cloud_access
  id = "RedHatCloudAccess"
}

import {
  to = aws_iam_role_policy_attachment.redhat_cloud_access
  id = "RedHatCloudAccess/arn:aws:iam::181841605684:policy/RedHatCloudAccess"
}

resource "aws_iam_policy" "redhat_cloud_access" {
  tags = local.redhat_tags

  name        = "RedHatCloudAccess"
  description = "Red Hat Cloud Access (cloudigrade): GetCallerIdentity only. To be imported into OpenTofu in phase 3."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "CloudigradePolicy"
      Effect   = "Allow"
      Action   = ["sts:GetCallerIdentity"]
      Resource = "*"
    }]
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role" "redhat_cloud_access" {
  tags = local.redhat_tags

  name        = "RedHatCloudAccess"
  description = "Assumed by Red Hat (998366406740) with external ID for Cloud Access. To be imported into OpenTofu in phase 3."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::998366406740:root" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "sts:ExternalId" = var.redhat_cloud_access_external_id }
      }
    }]
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "redhat_cloud_access" {
  role       = aws_iam_role.redhat_cloud_access.name
  policy_arn = aws_iam_policy.redhat_cloud_access.arn
}
