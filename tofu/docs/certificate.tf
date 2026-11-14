# Component of every taggable resource in this file (OpenTofu on AWS,
# pattern 5); merged with the provider's default tags.
locals {
  certificate_tags = { Component = "hosting" }
}

# The certificate of docs.taelron.com. Its DNS validation record is entered by
# hand in Microsoft 365 (output acm_validation_record) while the apply waits
# below. The wait stays under the one-hour session of the apply role.
resource "aws_acm_certificate" "site" {
  provider = aws.us_east_1

  tags = local.certificate_tags

  domain_name       = local.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "site" {
  provider = aws.us_east_1

  certificate_arn = aws_acm_certificate.site.arn

  timeouts {
    create = "45m"
  }
}
