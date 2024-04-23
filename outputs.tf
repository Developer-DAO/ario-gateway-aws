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
