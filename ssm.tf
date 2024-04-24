resource "aws_kms_key" "ssm" {
  description             = "Used by gateway instances to load SSM parameters"
  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy      = <<POLICY
  {
    "Version": "2012-10-17",
    "Id": "default",
    "Statement": [
      {
        "Sid": "DefaultAllow",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${var.account_id}:root"
        },
        "Action": "kms:*",
        "Resource": "*"
      }
    ]
  }
POLICY
}

resource "aws_ssm_parameter" "dotenv" {
  description = "Used to configure gateway instances"
  name        = "/ar-io-nodes/env"
  value       = file("${path.module}/resources/.env.gateway")
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
