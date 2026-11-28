# The host's data volumes (Platform Design Decisions, 14); the host OS volume
# is the instance's root volume. gp3, each with its own 3,000 IOPS and
# 125 MB/s. Mounted on the host by Ansible (M4), found by volume id.
#
# M5 (decided 17 November 2026, TAE-139): k3s, PostgreSQL and Garage are
# recreated smaller (a gp3 volume never shrinks), and the shared cluster's
# volume is added. The test and demo volumes come with their clusters.
#
# The M3 k3s, PostgreSQL and Garage volumes are deleted (TAE-139, step 1 check,
# decision 1) now that PostgreSQL is restored from pgBackRest on the new
# volume: their resources are gone from this file, and with them their
# prevent_destroy. AAP keeps its M3 volume, moved to resources of its own.

locals {
  # Inventory grouping (TAE-156): every taggable resource of this file.
  storage_tags = { Component = "storage" }

  # Created in M5. The shared VM's disk is handed to KVM as a raw disk
  # (role kvm).
  m5_volumes = {
    k3s        = { size = 20, device = "/dev/sdj" }
    postgresql = { size = 20, device = "/dev/sdk" }
    garage     = { size = 50, device = "/dev/sdl" }
    shared     = { size = 40, device = "/dev/sdm" }
  }
}

# AAP's volume, created in M3, unchanged in M5.
resource "aws_ebs_volume" "aap" {
  availability_zone = aws_subnet.public["a"].availability_zone
  type              = "gp3"
  size              = 30
  encrypted         = true

  tags = merge(local.storage_tags, {
    Name   = "platform-aap"
    Backup = "daily"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "aap" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.aap.id
  instance_id = aws_instance.host.id
}

moved {
  from = aws_ebs_volume.data["aap"]
  to   = aws_ebs_volume.aap
}

moved {
  from = aws_volume_attachment.data["aap"]
  to   = aws_volume_attachment.aap
}

resource "aws_ebs_volume" "m5" {
  for_each = local.m5_volumes

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

resource "aws_volume_attachment" "m5" {
  for_each = local.m5_volumes

  device_name = each.value.device
  volume_id   = aws_ebs_volume.m5[each.key].id
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
