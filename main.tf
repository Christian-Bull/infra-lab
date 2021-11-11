terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.default_region
}

# networking
resource "aws_vpc" "slack_vpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "slack_subnet" {
  vpc_id     = aws_vpc.slack_vpc.id
  cidr_block = var.vpc_subnet
}

resource "aws_internet_gateway" "slack_vpc" {
  vpc_id = aws_vpc.slack_vpc.id
}

resource "aws_route_table" "slack_route_table" {
  vpc_id = aws_vpc.slack_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.slack_vpc.id
  }
}

resource "aws_route_table_association" "slack_rta" {
  subnet_id      = aws_subnet.slack_subnet.id
  route_table_id = aws_route_table.slack_route_table.id
}

resource "aws_security_group" "slack_group" {
  name        = "inbound/outbound rules"
  description = "default ingress/egress traffic rules"
  vpc_id      = aws_vpc.slack_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ec2 resources

resource "aws_instance" "slack_slash_01" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_instance_type
  vpc_security_group_ids = [aws_security_group.slack_group.id]
  subnet_id              = aws_subnet.slack_subnet.id
  key_name               = var.key_name

  tags = {
    Name = "slack-slash"
  }
}

resource "aws_instance" "slack_slash_02" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_instance_type
  vpc_security_group_ids = [aws_security_group.slack_group.id]
  subnet_id              = aws_subnet.slack_subnet.id
  key_name               = var.key_name

  tags = {
    Name = "slack-slash"
  }
}

resource "aws_elb" "slack_twitch" {
  name    = "slack-slash-elb"
  subnets = [aws_subnet.slack_subnet.id]

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances    = [aws_instance.slack_slash_01.id, aws_instance.slack_slash_02.id]
  idle_timeout = 400

}

resource "aws_key_pair" "default_key" {
  key_name   = var.key_name
  public_key = var.pub_key
}