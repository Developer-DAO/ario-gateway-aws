resource "aws_codedeploy_app" "ar_io_nodes" {
  compute_platform = "Server"
  name             = "ar-io-nodes-${var.alias}"
}

resource "aws_codedeploy_deployment_group" "ar_io_nodes" {
  app_name              = aws_codedeploy_app.ar_io_nodes.name
  deployment_group_name = "ar-io-nodes-${var.alias}"
  service_role_arn      = aws_iam_role.ar_io_nodes_code_deploy_role.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  autoscaling_groups = [
    aws_autoscaling_group.ar_io_nodes_asg.name
  ]

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.ar_io_nodes_tg.name
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

resource "aws_s3_bucket" "codedeploy_deployments" {
  bucket_prefix = "ar-io-nodes-${var.alias}-codedeploy-"
  force_destroy = true # delete even if not empty
}

resource "aws_s3_bucket_ownership_controls" "codedeploy_deployments" {
  bucket = aws_s3_bucket.codedeploy_deployments.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "codedeploy_deployments" {
  bucket = aws_s3_bucket.codedeploy_deployments.id
  block_public_acls   = true
  block_public_policy = true
}

resource "aws_s3_bucket_versioning" "codedeploy_deployments" {
  bucket = aws_s3_bucket.codedeploy_deployments.id
  versioning_configuration {
    status = "Enabled"
  }
}