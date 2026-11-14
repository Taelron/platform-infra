# The platform's network (Platform Design Decisions, zones): one VPC, two
# public subnets in two availability zones (the load balancer needs both), an
# internet gateway. The instance lives in the first subnet at 10.20.1.10.

resource "aws_vpc" "platform" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "platform-vpc"
  }
}

locals {
  subnets = {
    a = { cidr = "10.20.1.0/24", zone = "eu-central-1a" }
    b = { cidr = "10.20.2.0/24", zone = "eu-central-1b" }
  }
}

resource "aws_subnet" "public" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.platform.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.zone
  map_public_ip_on_launch = false

  tags = {
    Name = "platform-public-${each.key}"
  }
}

resource "aws_internet_gateway" "platform" {
  vpc_id = aws_vpc.platform.id

  tags = {
    Name = "platform-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.platform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.platform.id
  }

  tags = {
    Name = "platform-public"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# The VPC's default security group allows nothing: every resource gets one of
# the groups below.
resource "aws_default_security_group" "platform" {
  vpc_id = aws_vpc.platform.id

  tags = {
    Name = "platform-default-deny"
  }
}

# --- Load balancer: HTTPS from anywhere, only to the host -----------------

resource "aws_security_group" "alb" {
  name        = "platform-alb"
  description = "Load balancer: HTTPS from the internet, to the host only"
  vpc_id      = aws_vpc.platform.id

  tags = {
    Name = "platform-alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from the internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_host" {
  security_group_id            = aws_security_group.alb.id
  description                  = "HTTPS to HAProxy on the host"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.host.id
}

# --- Host: 443 from the load balancer, 22 from the admin address -----------

resource "aws_security_group" "host" {
  name        = "platform-host"
  description = "platform-aws-01: HTTPS from the load balancer, SSH from the admin address"
  vpc_id      = aws_vpc.platform.id

  tags = {
    Name = "platform-host"
  }
}

resource "aws_vpc_security_group_ingress_rule" "host_https_from_alb" {
  security_group_id            = aws_security_group.host.id
  description                  = "HTTPS from the load balancer to HAProxy"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "host_ssh_admin" {
  security_group_id = aws_security_group.host.id
  description       = "SSH from the admin address only"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.admin_ssh_cidr
}

# Out: updates, Red Hat, container images, AWS APIs, S3 backups.
resource "aws_vpc_security_group_egress_rule" "host_all" {
  security_group_id = aws_security_group.host.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
