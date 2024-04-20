resource "aws_security_group" "ar_io_nodes_sg" {
  name        = "ar-io-node-${var.alias}-sg"
  description = "Allow inbound traffic from the internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound SSH in the private VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Allow inbound HTTP traffic on port 3000 in the private VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow outbound traffic to the internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  # 20.04 (not later) is required for CodeDeploy
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical Ltd.
}

resource "aws_cloudwatch_log_group" "ar_io_nodes_log_group" {
  name = "ar-io-nodes-${var.alias}"
}

resource "aws_launch_template" "ar_io_nodes_launch_template" {
  name = "ar-io-nodes-${var.alias}"

  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [
    aws_security_group.ar_io_nodes_sg.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.ar_io_nodes_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/resources/userdata.sh", {
    region         = var.region,
    fs_id          = aws_efs_file_system.cache_fs.id
    log_group_name = aws_cloudwatch_log_group.ar_io_nodes_log_group.name
  }))

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 40
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Environment     = var.alias
      Service         = "ar-io-nodes"
      DeploymentGroup = "ar-io-nodes-${var.alias}"
    }
  }
}

resource "aws_autoscaling_group" "ar_io_nodes_asg" {
  name                = "ar-io-nodes-${var.alias}"
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.ar_io_nodes_launch_template.id
    version = "$Latest" # TODO is this the right thing to do?
  }

  target_group_arns = [
    aws_lb_target_group.ar_io_nodes_tg.arn
  ]
}

resource "aws_efs_file_system" "cache_fs" {
  creation_token = "ar-io-nodes-${var.alias}-cache-fs"

  tags = {
    Environment = var.alias
    Service     = "ar-io-nodes"
  }

  # DONT'T DELETE THIS FILESYSTEM
  lifecycle {
    # prevent_destroy = true
    # workaround for old version of terraform (manually to 'elastic')
    ignore_changes = [throughput_mode]
  }
}

resource "aws_efs_mount_target" "cache_fs" {
  count = length(var.private_subnets)

  file_system_id  = aws_efs_file_system.cache_fs.id
  security_groups = [aws_security_group.cache_fs.id]
  subnet_id       = var.private_subnets[count.index]
}

resource "aws_security_group" "cache_fs" {
  name        = "ar-io-nodes-${var.alias}-cache-fs"
  description = "Allow access to EFS from the AR IO nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
