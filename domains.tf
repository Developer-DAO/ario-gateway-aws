resource "vercel_dns_record" "ar_io_root" {
  count = var.use_vercel_domains ? 1 : 0
  type    = "CNAME"
  domain  = var.domain_name
  name    = var.subdomain_name
  value   = aws_cloudfront_distribution.ar_io_cf.domain_name
  comment = "AR.IO gateway root (Terraform)"
}

resource "vercel_dns_record" "ar_io_sandbox" {
  count = var.use_vercel_domains ? 1 : 0
  type    = "CNAME"
  domain  = var.domain_name
  name    = "*.${var.subdomain_name}"
  value   = aws_cloudfront_distribution.ar_io_cf.domain_name
  comment = "AR.IO gateway sandbox (Terraform)"
}

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

resource "vercel_dns_record" "dns_validation" {
  count = var.use_vercel_domains ? 1 : 0
  comment = "AR.IO - DNS validation (Terraform)"
  domain  = var.domain_name
  name    = trimsuffix(tolist(aws_acm_certificate.alb.domain_validation_options)[0].resource_record_name, ".${var.domain_name}.")
  type    = tolist(aws_acm_certificate.alb.domain_validation_options)[0].resource_record_type
  value   = tolist(aws_acm_certificate.alb.domain_validation_options)[0].resource_record_value
  ttl     = 60
}