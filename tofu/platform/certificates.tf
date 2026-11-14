# The four wildcard certificates of the load balancer (Platform Design
# Decisions, 3), validated by DNS. taelron.com lives in Microsoft 365, so
# Gaetan enters the validation records by hand from the output
# m365_certificate_validation_records; AWS then issues and renews them.
# No aws_acm_certificate_validation here: it would hold the apply until the
# records exist. The load balancer step checks they are issued.

locals {
  public_zones = toset(["mgmt", "shared", "test", "demo"])
}

resource "aws_acm_certificate" "wildcard" {
  for_each = local.public_zones

  domain_name       = "*.${each.key}.taelron.com"
  validation_method = "DNS"

  tags = {
    Name = "platform-wildcard-${each.key}"
  }

  lifecycle {
    create_before_destroy = true
  }
}
