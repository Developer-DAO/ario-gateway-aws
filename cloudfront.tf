resource "aws_cloudfront_cache_policy" "default" {
  name    = "default-cache"
  comment = "The default cache policy"

  parameters_in_cache_key_and_forwarded_to_origin {
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Authorization", "Content-Length", "Content-Type", "Host"]
      }
    }

    cookies_config {
      cookie_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

resource "aws_cloudfront_response_headers_policy" "default" {
  name    = "ar-io-${var.alias}-default"
  comment = "The default header response policy: relaxed origin, secured CSP"

  cors_config {
    access_control_allow_credentials = false
    access_control_max_age_sec       = 3600

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_expose_headers {
      items = ["X-ArNS-Resolved-Id", "X-ArNS-TTL-Seconds"]
    }

    access_control_allow_methods {
      items = ["GET", "POST", "HEAD", "OPTIONS"]
    }

    access_control_allow_origins {
      items = ["*"]
    }

    origin_override = true
  }

  security_headers_config {
    # reference: https://infosec.mozilla.org/guidelines/web_security
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    strict_transport_security {
      access_control_max_age_sec = 3600
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "relaxed" {
  name    = "ar-io-${var.alias}-relaxed"
  comment = "A relaxed origin policy allowing cross origin requests"

  cookies_config {
    cookie_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "none"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Accept",
        "Access-Control-Allow-Headers",
        "Access-Control-Allow-Origin",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method",
        "Content-Length",
        "Content-Type",
        "Host",
        "Origin",
        "Referer"
      ]
    }
  }
}

resource "random_password" "ar_io_cf" {
  length  = 32
  special = false
}

resource "aws_cloudfront_distribution" "ar_io_cf" {
  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = aws_lb.alb.dns_name

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    custom_header {
      name  = "X-Origin-Secret"
      value = random_password.ar_io_cf.result
    }
  }

  enabled         = true
  is_ipv6_enabled = false
  price_class     = "PriceClass_100" # TODO move to var

  aliases = [
    "${var.subdomain_name}.${var.domain_name}", 
    "*.${var.subdomain_name}.${var.domain_name}"
  ]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_lb.alb.dns_name
    compress         = true

    cache_policy_id            = aws_cloudfront_cache_policy.default.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.relaxed.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.default.id

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
    acm_certificate_arn      = aws_acm_certificate.cloudfront.arn
  }
}
