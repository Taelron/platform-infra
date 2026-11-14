output "backup_buckets" {
  description = "Backup buckets: pgBackRest and OpenBao snapshots"
  value       = { for k, b in aws_s3_bucket.backup : k => b.bucket }
}

output "vpc_id" {
  description = "VPC of the platform"
  value       = aws_vpc.platform.id
}

output "subnet_ids" {
  description = "Public subnets, by zone letter"
  value       = { for k, s in aws_subnet.public : k => s.id }
}
