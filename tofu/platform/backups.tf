# Backup buckets: pgBackRest for PostgreSQL, Raft snapshots for each OpenBao
# (Platform Design Decisions, 7 and 23). Versioned, so an overwritten or
# deleted backup stays recoverable for 30 days; retention of the backups
# themselves is set by pgBackRest and OpenBao.
locals {
  # Inventory grouping (TAE-156): every taggable resource of this file.
  backups_tags = { Component = "backups" }
  backup_buckets = {
    pgbackrest = "platform-pgbackrest-${local.account_id}"
    openbao    = "platform-openbao-snapshots-${local.account_id}"
  }
}

resource "aws_s3_bucket" "backup" {
  for_each = local.backup_buckets

  bucket = each.value

  tags = local.backups_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "backup" {
  for_each = aws_s3_bucket.backup

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  for_each = aws_s3_bucket.backup

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backup" {
  for_each = aws_s3_bucket.backup

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "backup" {
  for_each = aws_s3_bucket.backup

  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  for_each = aws_s3_bucket.backup

  bucket = each.value.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.backup]
}

data "aws_iam_policy_document" "backup_tls_only" {
  for_each = aws_s3_bucket.backup

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [each.value.arn, "${each.value.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "backup" {
  for_each = aws_s3_bucket.backup

  bucket = each.value.id
  policy = data.aws_iam_policy_document.backup_tls_only[each.key].json

  depends_on = [aws_s3_bucket_public_access_block.backup]
}
