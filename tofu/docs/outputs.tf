# What the publisher of the pages needs.

output "bucket_name" {
  description = "The bucket the pages are uploaded to (PutObject)."
  value       = aws_s3_bucket.site.bucket
}

output "distribution_id" {
  description = "The distribution to invalidate after a publish (CreateInvalidation)."
  value       = aws_cloudfront_distribution.site.id
}

# The two records Gaetan enters in Microsoft 365, zone taelron.com.

output "acm_validation_record" {
  description = "Microsoft 365: the CNAME that validates the certificate of docs.taelron.com."
  value = one([
    for o in aws_acm_certificate.site.domain_validation_options : {
      type  = o.resource_record_type
      name  = o.resource_record_name
      host  = trimsuffix(o.resource_record_name, ".taelron.com.")
      value = o.resource_record_value
    }
  ])
}

output "docs_cname" {
  description = "Microsoft 365: the CNAME of docs.taelron.com to CloudFront."
  value = {
    type  = "CNAME"
    host  = "docs"
    value = aws_cloudfront_distribution.site.domain_name
  }
}

output "publish_role_arn" {
  description = "The role the publish workflow of Taelron/taelron-docs-site assumes."
  value       = aws_iam_role.publish.arn
}
