output "state_bucket" {
  description = "S3 bucket holding the OpenTofu state of every root"
  value       = aws_s3_bucket.state.bucket
}

output "plan_role_arn" {
  description = "Role GitHub Actions assumes for tofu plan on pull requests"
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Role GitHub Actions assumes for tofu apply in environment production"
  value       = aws_iam_role.apply.arn
}
