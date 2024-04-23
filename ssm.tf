resource "aws_kms_key" "ssm" {
  description             = "Used by gateway instances to load SSM parameters"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7
}

resource "aws_ssm_parameter" "dotenv" {
  description = "Used to configure gateway instances"
  name        = "/ar-io-nodes/env"
  value       = file("${path.module}/resources/.env.gateway.test")
  type        = "SecureString"
  key_id      = aws_kms_key.ssm.key_id
}

resource "aws_ssm_parameter" "observer-key" {
  description = "Used by gateway observer to submit reports to Arweave"
  name        = "/ar-io-nodes/observer-key"
  value       = var.observer_key
  type        = "SecureString"
  key_id      = aws_kms_key.ssm.key_id
}
