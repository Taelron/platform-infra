# The host's data volumes (Platform Design Decisions, 14); the host OS volume
# is the instance's root volume. gp3, each with its own 3,000 IOPS and
# 125 MB/s. Mounted on the host by Ansible (M4), found by volume id.
#
# M5 (decided 17 November 2026, TAE-139): k3s, PostgreSQL and Garage are
# recreated smaller (a gp3 volume never shrinks), and the shared cluster's
# volume is added. The test and demo volumes come with their clusters.
#
# The M3 volumes stay in aws_ebs_volume.data, still guarded by
# prevent_destroy. k3s, PostgreSQL and Garage are detached from the host and
# renamed platform-<name>-m3; a later pull request deletes them once
# PostgreSQL is restored from pgBackRest on the new volume (TAE-139, step 1
# check, decision 1). AAP keeps its M3 volume.

locals {
  # Inventory grouping (TAE-156): every taggable resource of this file.
  storage_tags = { Component = "storage" }

  # Created in M3. attached = false: detached, waiting to be deleted.
  m3_volumes = {
    k3s        = { size = 30, device = "/dev/sdf", attached = false }
    postgresql = { size = 80, device = "/dev/sdg", attached = false }
    aap        = { size = 30, device = "/dev/sdh", attached = true }
    garage     = { size = 100, device = "/dev/sdi", attached = false }
  }

  # Created in M5. New device names: the M3 volumes free theirs in the same
  # apply, in no guaranteed order.
  m5_volumes = {
    k3s        = { size = 20, device = "/dev/sdj" }
    postgresql = { size = 20, device = "/dev/sdk" }
    garage     = { size = 50, device = "/dev/sdl" }
    # The shared VM's disk: handed to KVM as a raw disk (role kvm).
    shared = { size = 40, device = "/dev/sdm" }
  }
}

resource "aws_ebs_volume" "data" {
  for_each = local.m3_volumes

  availability_zone = aws_subnet.public["a"].availability_zone
  type              = "gp3"
  size              = each.value.size
  encrypted         = true

  tags = merge(local.storage_tags, {
    Name   = each.value.attached ? "platform-${each.key}" : "platform-${each.key}-m3"
    Backup = "daily"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "data" {
  for_each = { for k, v in local.m3_volumes : k => v if v.attached }

  device_name = each.value.device
  volume_id   = aws_ebs_volume.data[each.key].id
  instance_id = aws_instance.host.id
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
