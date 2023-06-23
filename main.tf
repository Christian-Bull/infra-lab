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

  default_tags {
    tags = {
      Name   = "app-host"
      Author = "Terraform"
    }
  }
}

# networking
resource "aws_vpc" "slack_vpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "slack_subnet" {
  vpc_id                  = aws_vpc.slack_vpc.id
  cidr_block              = var.vpc_subnet
  map_public_ip_on_launch = true
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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [var.whitelist_ip]
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
    Name = "app-host-1"
  }
}

resource "aws_key_pair" "default_key" {
  key_name   = var.key_name
  public_key = var.pub_key
}

resource "aws_eip" "lb" {
  instance = aws_instance.slack_slash_01.id
}