# The Application Load Balancer (Platform Design Decisions, 2 and 3): one
# HTTPS entry point for every public name. It ends TLS with the four wildcard
# certificates and forwards, re-encrypted, to HAProxy on the host at
# 10.20.1.10:443, which routes each name (Phase 4). No port 80: certificates
# come from ACM, so nothing needs HTTP. AWS WAF attaches here once clients
# have logins.

locals {
  # Inventory grouping (TAE-156): every taggable resource of this file.
  load_balancer_tags = { Component = "load-balancer" }

  # The certificate the listener presents when a client sends no SNI name.
  default_certificate_zone = "mgmt"
}

resource "aws_lb" "platform" {
  name                       = "platform-alb"
  load_balancer_type         = "application"
  internal                   = false
  subnets                    = [for s in aws_subnet.public : s.id]
  security_groups            = [aws_security_group.alb.id]
  drop_invalid_header_fields = true
  enable_deletion_protection = true

  tags = local.load_balancer_tags
}

# IP target: HAProxy on the host's VPC address, over HTTPS. Until HAProxy runs
# (Phase 4) the target is unhealthy and the load balancer answers 503.
resource "aws_lb_target_group" "host" {
  name        = "platform-host-https"
  target_type = "ip"
  protocol    = "HTTPS"
  port        = 443
  vpc_id      = aws_vpc.platform.id

  # Any HTTP answer from HAProxy means the host is up; which name answers
  # what is HAProxy's business, not the load balancer's.
  health_check {
    protocol            = "HTTPS"
    port                = "traffic-port"
    path                = "/"
    matcher             = "200-499"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = local.load_balancer_tags
}

resource "aws_lb_target_group_attachment" "host" {
  target_group_arn = aws_lb_target_group.host.arn
  target_id        = local.host_ip
  port             = 443
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.platform.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.wildcard[local.default_certificate_zone].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.host.arn
  }

  tags = local.load_balancer_tags
}

# The three other wildcards, chosen by SNI.
resource "aws_lb_listener_certificate" "wildcard" {
  for_each = setsubtract(local.public_zones, [local.default_certificate_zone])

  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = aws_acm_certificate.wildcard[each.key].arn
}
