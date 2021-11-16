variable "vpc_subnet" {
  type    = string
  default = "10.0.0.0/24"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "ec2_ami" {
  type    = string
  default = null
}

variable "default_region" {
  type    = string
  default = "us-east-1"
}

variable "ec2_instance_type" {
  type    = string
  default = null
}

variable "key_name" {
  type    = string
  default = "aws_key"
}

variable "pub_key" {
  type    = string
  default = null
}

variable "whitelist_ip" {
  type = string
  default = null
}