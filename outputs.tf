output LogGroup {
  description = "CloudWatch Logs"
  value = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#logsV2:log-groups/log-group/${aws_cloudwatch_log_group.ar_io_nodes_log_group.name}"
}

output GatewayAlias {
  description = "Infix for resource names of this deployment."
  value = var.alias
}

output GatewayUrl {
  description = "Public URL of the gateway"
  value = "https://${var.subdomain_name}.${var.domain_name}/"
}

output CodeDeployBucket {
  description = "Bucket for CodeDeploy deployments"
  value       = aws_s3_bucket.codedeploy_deployments.id
}

output CloudFrontDomain {
  description = "Domain of the CloudFront Distribution"
  value       = aws_cloudfront_distribution.ar_io_cf.domain_name
}

output CertValidationRecordType {
  description = "Name of the DNS record used for certificate validation."
  value       = tolist(aws_acm_certificate.alb.domain_validation_options)[0].resource_record_type
}

output CertValidationRecordName {
  description = "Name of the DNS record used for certificate validation."
  value       = trimsuffix(tolist(aws_acm_certificate.alb.domain_validation_options)[0].resource_record_name, ".${var.domain_name}.")
}

output CertValidationRecordValue {
  description = "Value of the DNS record used for certificate validation."
  value       = tolist(aws_acm_certificate.alb.domain_validation_options)[0].resource_record_value
}
