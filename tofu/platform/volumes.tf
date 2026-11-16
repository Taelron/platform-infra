# The host's data volumes (Platform Design Decisions, 14); the host OS volume
# is the instance's root volume. gp3, each with its own 3,000 IOPS and
# 125 MB/s. Mounted on the host by Ansible (Phase 4), found by volume id.
#
# Each cluster's volume (shared, test, demo) is created with its cluster in
# Phase 5, not before: PO decision, 14 November 2026.

locals {
  # Inventory grouping (TAE-156): every taggable resource of this file.
  storage_tags = { Component = "storage" }
  data_volumes = {
    k3s        = { size = 30, device = "/dev/sdf" }
    postgresql = { size = 80, device = "/dev/sdg" }
    aap        = { size = 30, device = "/dev/sdh" }
    garage     = { size = 100, device = "/dev/sdi" }
  }
}

resource "aws_ebs_volume" "data" {
  for_each = local.data_volumes

  availability_zone = aws_subnet.public["a"].availability_zone
  type              = "gp3"
  size              = each.value.size
  encrypted         = true

  tags = merge(local.storage_tags, {
    Name   = "platform-${each.key}"
    Backup = "daily"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "data" {
  for_each = local.data_volumes

  device_name = each.value.device
  volume_id   = aws_ebs_volume.data[each.key].id
  instance_id = aws_instance.host.id
}

# --- Daily snapshots of every volume tagged Backup=daily, kept 7 days -------

data "aws_iam_policy_document" "dlm_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dlm" {
  name               = "platform-dlm"
  description        = "Data Lifecycle Manager: daily snapshots of the platform volumes"
  assume_role_policy = data.aws_iam_policy_document.dlm_trust.json

  tags = local.storage_tags
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = aws_iam_role.dlm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

resource "aws_dlm_lifecycle_policy" "daily" {
  description        = "platform-daily-snapshots"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    target_tags = {
      Backup = "daily"
    }

    schedule {
      name      = "daily-7-days"
      copy_tags = true

      # 21:00 UTC, before the nightly stop at 23:00 Brussels time.
      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["21:00"]
      }

      retain_rule {
        count = 7
      }
    }
  }

  tags = merge(local.storage_tags, {
    Name = "platform-daily-snapshots"
  })
}
