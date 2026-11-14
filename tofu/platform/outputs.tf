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

# To enter in Microsoft 365, DNS of taelron.com: one CNAME per certificate.
# "host" is the name relative to taelron.com, as the Microsoft 365 form asks.
output "m365_certificate_validation_records" {
  description = "CNAME records validating the wildcard certificates, for Microsoft 365"
  value = {
    for zone, cert in aws_acm_certificate.wildcard : zone => {
      for o in cert.domain_validation_options : o.domain_name => {
        type  = o.resource_record_type
        host  = trimsuffix(trimsuffix(o.resource_record_name, "."), ".taelron.com")
        value = trimsuffix(o.resource_record_value, ".")
      }
    }
  }
}

output "host" {
  description = "platform-aws-01: instance id, private address, SSH address"
  value = {
    instance_id = aws_instance.host.id
    private_ip  = aws_instance.host.private_ip
    ssh_ip      = aws_eip.ssh.public_ip
  }
}

# To enter in Microsoft 365, DNS of taelron.com: one wildcard CNAME per zone
# to the load balancer (Platform Design Decisions, 12). "host" is relative to
# taelron.com. If Microsoft 365 refuses a wildcard, one CNAME per name instead.
output "m365_load_balancer_cnames" {
  description = "Wildcard CNAME records to the load balancer, for Microsoft 365"
  value = {
    for zone in sort(tolist(local.public_zones)) : zone => {
      type  = "CNAME"
      host  = "*.${zone}"
      value = aws_lb.platform.dns_name
    }
  }
}
