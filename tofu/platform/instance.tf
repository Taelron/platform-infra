# The host platform-aws-01 (Platform Design Decisions, 1, 2, 9): RHEL 9 from
# the Red Hat gold image (no Red Hat fee per hour), nested virtualization on
# for KVM, private address 10.20.1.10, Elastic IP 1 for SSH.
#
# Size: r8i.2xlarge (8 vCPU, 64 GB) to start, decided by Gaetan on 14 November
# 2026; enough for the host's own services (Phases 3 and 4). Resized to
# r8i.4xlarge at the start of Phase 5, before the shared VM: the host and the
# shared VM need 60 GB, and the r8i.2xlarge shows 61. Changing instance_type
# stops, resizes and starts the instance in place, same volumes and addresses.
#
# First apply (14 November 2026) stopped at the instance: AWS answered
# PendingVerification while it validated the new account's access to
# eu-central-1. Dry-run launches do not show that check.

locals {
  # Inventory grouping (TAE-156): every taggable resource of this file.
  host_tags = { Component = "host" }
  # RHEL-9.8.0_HVM-20261021-x86_64-0-Access2-GP3, Red Hat Cloud Access gold
  # image. Pinned: a newer image must never replace the host silently.
  rhel_gold_ami = "ami-0c9e7ae53e5477621"
  host_ip       = "10.20.1.10"
}

resource "aws_key_pair" "platform" {
  key_name   = "platform-admin"
  public_key = file("${path.module}/keys/taelron-platform.pub")

  tags = local.host_tags
}

# --- Instance role: Session Manager and the backup buckets ------------------

data "aws_iam_policy_document" "host_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "host" {
  name               = "platform-host"
  description        = "platform-aws-01: Session Manager and the backup buckets"
  assume_role_policy = data.aws_iam_policy_document.host_trust.json

  tags = local.host_tags
}

resource "aws_iam_role_policy_attachment" "host_ssm" {
  role       = aws_iam_role.host.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "host_backups" {
  statement {
    sid       = "BackupBuckets"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [for b in aws_s3_bucket.backup : b.arn]
  }

  statement {
    sid       = "BackupObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [for b in aws_s3_bucket.backup : "${b.arn}/*"]
  }
}

resource "aws_iam_role_policy" "host_backups" {
  name   = "backups"
  role   = aws_iam_role.host.id
  policy = data.aws_iam_policy_document.host_backups.json
}

resource "aws_iam_instance_profile" "host" {
  name = "platform-host"
  role = aws_iam_role.host.name

  tags = local.host_tags
}

# --- The instance -----------------------------------------------------------

resource "aws_instance" "host" {
  ami                     = local.rhel_gold_ami
  instance_type           = "r8i.2xlarge"
  subnet_id               = aws_subnet.public["a"].id
  private_ip              = local.host_ip
  vpc_security_group_ids  = [aws_security_group.host.id]
  key_name                = aws_key_pair.platform.key_name
  iam_instance_profile    = aws_iam_instance_profile.host.name
  disable_api_termination = true

  cpu_options {
    nested_virtualization = "enabled"
  }

  # IMDSv2 only, one hop: programs on the host reach it, the KVM virtual
  # machines and containers behind a bridge do not.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # The host OS volume (50 GB); the seven others are in volumes.tf.
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    encrypted             = true
    delete_on_termination = true

    tags = merge(local.host_tags, {
      Name   = "platform-aws-01-os"
      Backup = "daily"
    })
  }

  tags = merge(local.host_tags, {
    Name = "platform-aws-01"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Elastic IP 1: SSH from the admin address only (security group platform-host).
resource "aws_eip" "ssh" {
  domain   = "vpc"
  instance = aws_instance.host.id

  tags = merge(local.host_tags, {
    Name = "platform-ssh"
  })
}
