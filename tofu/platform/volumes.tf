# The seven data volumes (Platform Design Decisions, 14); the host OS volume is
# the instance's root volume. gp3, each with its own 3,000 IOPS and 125 MB/s.
# Mounted on the host or given to KVM by Ansible (Phase 4), found by volume id.

locals {
  data_volumes = {
    k3s        = { size = 30, device = "/dev/sdf" }
    postgresql = { size = 80, device = "/dev/sdg" }
    aap        = { size = 30, device = "/dev/sdh" }
    garage     = { size = 100, device = "/dev/sdi" }
    shared     = { size = 40, device = "/dev/sdj" }
    test       = { size = 100, device = "/dev/sdk" }
    demo       = { size = 100, device = "/dev/sdl" }
  }
}

resource "aws_ebs_volume" "data" {
  for_each = local.data_volumes

  availability_zone = aws_subnet.public["a"].availability_zone
  type              = "gp3"
  size              = each.value.size
  encrypted         = true

  tags = {
    Name   = "platform-${each.key}"
    Backup = "daily"
  }

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

  tags = {
    Name = "platform-daily-snapshots"
  }
}
