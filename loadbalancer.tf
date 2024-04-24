resource "aws_security_group" "alb" {
  name   = "ar-io-lb-${var.alias}-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  name                       = "ar-io-${var.alias}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.public_subnets
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "ar_io_nodes_tg" {
  name        = "ar-io-nodes-${var.alias}-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    matcher = "200-299"
    path    = "/ar-io/healthcheck"
    timeout = 4 
    interval = 20
    healthy_threshold = 2
    unhealthy_threshold = 2
  }

  load_balancing_algorithm_type = "least_outstanding_requests"
}

resource "aws_lb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_lb_listener" "alb_https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn   = aws_acm_certificate.alb.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access denied"
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "alb_https_listener_general_rule" {
  listener_arn = aws_lb_listener.alb_https_listener.arn
  priority     = 120

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ar_io_nodes_tg.arn
  }

  condition {
    http_header {
      http_header_name = "X-Origin-Secret"
      values           = [random_password.ar_io_cf.result]
    }
  }
}

resource "aws_wafv2_ip_set" "graphql_ip_allow_list" {
  name               = "graphql-allow-list"
  description        = "IP set which wont ever be rate-limited on /graphql"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = [for ip in var.graphql_ip_allow_list : "${ip}/32"]
}

resource "aws_wafv2_web_acl" "alb_waf" {
  name        = "ar-io-${var.alias}-rules"
  description = "Legacy gateway rules."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "aws-known-bad-inputs-rule"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ar-io-${var.alias}-aws-known-bad-inputs-rule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-ip-reputation-rule"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ar-io-${var.alias}-aws-ip-reputation-rule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "tx-header-rate-limit-rule"
    priority = 10

    action {
      block {
        custom_response {
          response_code = 429
        }
      }
    }

    statement {
      rate_based_statement {
        limit              = 4500 # 15/sec
        aggregate_key_type = "FORWARDED_IP"
        forwarded_ip_config {
          header_name       = "X-Forwarded-For"
          fallback_behavior = "NO_MATCH"
        }

        scope_down_statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "STARTS_WITH"
            search_string         = "/tx/"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ar-io-${var.alias}-header-rate-limit-rule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "graphql-rate-limit-rule"
    priority = 11

    action {
      block {
        custom_response {
          response_code = 429
        }
      }
    }

    statement {
      rate_based_statement {
        limit              = 600 # 2/sec
        aggregate_key_type = "FORWARDED_IP"
        forwarded_ip_config {
          header_name       = "X-Forwarded-For"
          fallback_behavior = "NO_MATCH"
        }

        scope_down_statement {
          and_statement {
            statement {
              byte_match_statement {
                field_to_match {
                  uri_path {}
                }
                positional_constraint = "STARTS_WITH"
                search_string         = "/graphql"
                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }

            statement {
              not_statement {
                statement {
                  ip_set_reference_statement {
                    arn = aws_wafv2_ip_set.graphql_ip_allow_list.arn
                    ip_set_forwarded_ip_config {
                      header_name       = "X-Forwarded-For"
                      fallback_behavior = "NO_MATCH"
                      position          = "FIRST"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ar-io-${var.alias}-graphql-rate-limit-rule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "global-rate-limit-rule"
    priority = 12

    action {
      block {
        custom_response {
          response_code = 429
        }
      }
    }

    statement {
      rate_based_statement {
        limit              = 30000 # 100/sec
        aggregate_key_type = "FORWARDED_IP"
        forwarded_ip_config {
          header_name       = "X-Forwarded-For"
          fallback_behavior = "NO_MATCH"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ar-io-${var.alias}-global-rate-limit-rule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ar-io-${var.alias}-rules"
    sampled_requests_enabled   = true
  }
}
