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
