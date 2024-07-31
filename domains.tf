resource "aws_acm_certificate" "cloudfront" {
  provider                  = aws.us-east-1
  domain_name               = "${var.subdomain_name}.${var.domain_name}"
  subject_alternative_names = [
    "${var.subdomain_name}.${var.domain_name}", 
    "*.${var.subdomain_name}.${var.domain_name}"
  ]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "alb" {
  domain_name               = "${var.subdomain_name}.${var.domain_name}"
  subject_alternative_names = [
    "${var.subdomain_name}.${var.domain_name}", 
    "*.${var.subdomain_name}.${var.domain_name}"
  ]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}