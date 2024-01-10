terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "jenkins-project-backend-ersin"
    key = "backend/tf-backend-jenkins.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

# data "aws_ami" "red_hat" {
#   most_recent      = true
#   owners           = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["RHEL_HA-9.0.0*"]
#   }

#   filter {
#     name   = "platform"
#     values = ["Red Hat"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

data "aws_vpc" "default" {
  default = true
}


locals {
  instance_tags = ["postgresql", "nodejs", "react"]
}

resource "aws_instance" "servers" {
  ami = "ami-05a5f6298acdb05b6" #data.aws_ami.red_hat.id
  count = var.number
  instance_type = "t2.micro"
  key_name = var.key_name
  iam_instance_profile = "ecr-ansible-profile-${var.user}"
  vpc_security_group_ids = [aws_security_group.security_group.id]
  user_data = <<-EOF
              #! /bin/bash
              dnf update -y
              EOF
  tags = {
    Name = element(local.instance_tags, count.index)
    stack = "ansible_project"
    environment = "development"
  }
}

resource "aws_iam_role" "ecr-full-access" {
  name = "ecr_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"]
}

resource "aws_iam_instance_profile" "ansible-instance-profile" {
  name = "ecr-ansible-profile-${var.user}"
  role = aws_iam_role.ecr-full-access.name
}

resource "aws_security_group" "security_group" {
  name        = "jenkins_project"
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.default.id
    tags = {
    Name = "jenkins_project_sec_grp"
  }

  dynamic "ingress" {
    for_each = toset(var.allow_ports)
    content {
    from_port   = ingress.value
    protocol    = "tcp"
    to_port     = ingress.value
    cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}