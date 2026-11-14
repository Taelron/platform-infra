output "backup_buckets" {
  description = "Backup buckets: pgBackRest and OpenBao snapshots"
  value       = { for k, b in aws_s3_bucket.backup : k => b.bucket }
}
