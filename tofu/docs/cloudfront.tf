data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "docs-site"
  description                       = "Taelron Docs reads its bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

locals {
  origin_id = "docs-site"

  # Sign-in, refresh and sign-out: answered by their edge function, never by
  # the bucket.
  auth_behaviors = {
    (local.edge_paths.sign_in)  = "parse-auth"
    (local.edge_paths.refresh)  = "refresh-auth"
    (local.edge_paths.sign_out) = "sign-out"
  }
}

resource "aws_cloudfront_distribution" "site" {
  comment             = "docs-site: Taelron Docs"
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  price_class         = "PriceClass_100"
  aliases             = [local.domain_name]
  wait_for_deployment = true

  origin {
    origin_id                = local.origin_id
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  # Every page: sign-in and space check on the viewer request (directory
  # index included), security headers and the denied page's 403 on the origin
  # response.
  default_cache_behavior {
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.optimized.id

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = aws_lambda_function.edge["check-auth"].qualified_arn
    }

    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = aws_lambda_function.edge["http-headers"].qualified_arn
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.auth_behaviors

    content {
      path_pattern           = ordered_cache_behavior.key
      target_origin_id       = local.origin_id
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      compress               = true
      cache_policy_id        = data.aws_cloudfront_cache_policy.disabled.id

      lambda_function_association {
        event_type = "viewer-request"
        lambda_arn = aws_lambda_function.edge[ordered_cache_behavior.value].qualified_arn
      }
    }
  }

  # A page that does not exist: the site's own not-found page, published with
  # the others under site/not-found/, with the status 404. Cached briefly, so
  # that a page published just after is found.
  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/not-found/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
