terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  id = var.vpc_id
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnet" "available" {
  for_each = toset(data.aws_subnets.available.ids)
  id       = each.value
}

resource "random_shuffle" "vpc_subnet_pair" {
  input        = data.aws_subnets.available.ids
  result_count = 2
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Create a dedicated EC2 Security Group to grant ingress and 
network traffic to the EC2 instance via the default Subnet, 
Internet Gateway and Routing.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_security_group" "happy_bird_ingress" {
  name        = "happy_bird_ingress"
  description = "Happy Bird outbound traffic"
  vpc_id      = data.aws_vpc.default.id
  tags        = merge({ "Name" = "Happy Bird App Outbound" }, var.tags)
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Create a dedicated EC2 Security Group to grant egress and 
network traffic to the EC2 instances via the default Subnet, 
Internet Gateway and Routing.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_security_group" "happy_bird_egress" {
  name        = "happy_bird_egress"
  description = "Happy Bird outbound traffic"
  vpc_id      = data.aws_vpc.default.id
  tags        = merge({ "Name" = "Happy Bird App Outbound" }, var.tags)
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Explicitly allow all egress traffic for the scurity group. 
The CIDR should be changed to reflect the localized working
environment in the demo platform.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_security_group_rule" "egress_allow_all" {
  description       = "Allow all outbound traffic."
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.happy_bird_ingress.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Explicitly accept SSH traffic.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_security_group_rule" "allow_ssh" {
  description       = "SSH Connection"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.happy_bird_ingress.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Explicitly accept HTTP traffic.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_security_group_rule" "allow_http" {
  description       = "HTTP Connection"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.happy_bird_egress.id
}

# Create a new instance of the latest Ubuntu on an EC2 instance,
# t2.micro node. We can find more options using the AWS command line:
#
#  aws ec2 describe-images --owners 099720109477 \
#    --filters "Name=name,Values=*hvm-ssd*bionic*18.04-amd64*" \
#    --query 'sort_by(Images, &CreationDate)[].Name'
#
# aws ec2 describe-images --owners 099720109477 \
#   --filters "Name=name,Values=*hvm-ssd*focal*20.04-amd64*" \
#   --query 'sort_by(Images, &CreationDate)[].Name'

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Define a private key pair to access the EC2 instance. Do not
expose the key outside fo the demo platform environment.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tls_private_key" "main" {
  algorithm = "RSA"
}

locals {
  private_key_filename = "happy-bird-ssh-key"
}

resource "aws_key_pair" "main" {
  key_name   = local.private_key_filename
  public_key = tls_private_key.main.public_key_openssh
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Saving the key locally as an optional use case. It is not 
necessary for the demo sequence and can be omitted.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "null_resource" "main" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.main.private_key_pem}\" > happy-animals-ssh-key.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 happy-animals-ssh-key.pem"
  }
}

/**** **** **** **** **** **** **** **** **** **** **** ****
To build our simple Web application, we need to obtain
the bootstrap script for Nginx and the Web app. 
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_launch_template" "lt" {
  name          = "happy-animals-ec2-asg-lt"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.main.key_name
  user_data     = filebase64("${path.module}/templates/user-data.bash.tpl")

  vpc_security_group_ids = [
    aws_security_group.happy_bird_egress.id,
    aws_security_group.happy_bird_ingress.id
  ]

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      { "Name" = "happy-animals-ec2" },
      { "Type" = "autoscaling-group" },
      { "OS_Distro" = "Ubuntu Focal" },
      var.tags
    )
  }

  monitoring {
    enabled = true
  }

    tags = merge({
      "Name"          = "happy-animals-ec2-launch-template"
      },
      var.tags
    )
}

resource "aws_lb" "lb" {
  name                             = "happy-bird-lb"
  internal                         = false
  load_balancer_type               = "application"
  subnets                          = random_shuffle.vpc_subnet_pair.result
  drop_invalid_header_fields       = true
  enable_cross_zone_load_balancing = true

  security_groups = [
    aws_security_group.happy_bird_ingress.id,
    aws_security_group.happy_bird_egress.id
  ]
  tags = merge({ "Name" = "Happy Bird App ALB" }, var.tags)
}

output "aws_lb_arn" {
  value = aws_lb.lb.arn
}

resource "aws_lb_listener" "alb_listeners" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tgs.arn
  }
  tags = merge({ "Name" = "Happy Bird ALB Listener" }, var.tags)
}

resource "aws_lb_target_group" "lb_tgs" {
  name                   = "happy-animals-lb-target-group"
  port                   = 80
  connection_termination = false
  protocol               = "HTTP"
  vpc_id                 = data.aws_vpc.default.id
}

resource "aws_autoscaling_group" "asg" {
  name                      = "happy-animals-asg"
  min_size                  = 2
  max_size                  = 2
  desired_capacity          = 2
  vpc_zone_identifier       = random_shuffle.vpc_subnet_pair.result
  health_check_grace_period = 900
  health_check_type         = "ELB"
  wait_for_capacity_timeout = "10m"
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.lb_tgs.arn]

  tag {
    key                 = "Name"
    value               = "happy-animals-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Active-Active"
    value               = true
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }
}

resource "aws_autoscaling_lifecycle_hook" "alh" {
  name                   = "happy-animals-asg-hook"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  heartbeat_timeout      = 1500
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}
