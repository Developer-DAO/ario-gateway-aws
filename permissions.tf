resource "aws_iam_role" "ar_io_nodes_code_deploy_role" {
  name = "ar-io-nodes-code-deploy-${var.alias}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.ar_io_nodes_code_deploy_role.name
}

resource "aws_iam_role" "ar_io_nodes_instance_role" {
  name = "ar-io-nodes-instance-${var.alias}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ar_io_nodes_instance_role_policy" {
  name = "ar-io-nodes-instance-${var.alias}-role-policy"
  role = aws_iam_role.ar_io_nodes_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Action": [
          "ssmmessages:*",
          "ec2messages:*",
          "ssm:UpdateInstanceInformation"
        ],
        "Resource": "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:DescribeParameter"
        ],
        Resource = [
          "arn:aws:ssm:${var.region}:${var.account_id}:parameter/ar-io-nodes/*",
          "arn:aws:ssm:${var.region}:${var.account_id}:parameter/ar-io-nodes"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ],
        Resource = [
          "arn:aws:kms:${var.region}:${var.account_id}:key/${aws_kms_key.ssm.key_id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
        Resource = [
          "${aws_s3_bucket.codedeploy_deployments.arn}",
          "${aws_s3_bucket.codedeploy_deployments.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.region}:${var.account_id}:log-group:${aws_cloudwatch_log_group.ar_io_nodes_log_group.name}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRoleForEC2Instance" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeployLimited"
  role       = aws_iam_role.ar_io_nodes_instance_role.name
}

resource "aws_iam_instance_profile" "ar_io_nodes_instance_profile" {
  name = "ar-io-nodes-instance-${var.alias}-profile"
  role = aws_iam_role.ar_io_nodes_instance_role.name
}

resource "aws_iam_policy" "ar_io_nodes_deploy_policy" {
  name        = "ar-io-nodes-deploy-${var.alias}-policy"
  path        = "/"
  description = "Allows access to deploy ar.io nodes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetApplicationRevision"
        ],
        Effect = "Allow"
        Resource = [
          "arn:aws:codedeploy:${var.region}:${var.account_id}:application:ar-io-nodes-${var.alias}",
          "arn:aws:codedeploy:${var.region}:${var.account_id}:deploymentconfig:CodeDeployDefault.OneAtATime",
          "arn:aws:codedeploy:${var.region}:${var.account_id}:deploymentgroup:ar-io-nodes-${var.alias}/*"
        ]
      },
      {
        Action = [
          "s3:Get*",
          "s3:PutObject",
        ],
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.codedeploy_deployments.arn}",
          "${aws_s3_bucket.codedeploy_deployments.arn}/*"
        ]
      }
    ]
  })
}