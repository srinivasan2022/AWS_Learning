variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_name" {
  type    = string
  default = "linux-vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnets" {
  description = "Map of public subnets"
  type = map(object({
    name = string
    cidr = string
    az   = string
  }))
}

variable "security_groups" {
  description = "Map of security groups"
  type = map(object({
    name        = string
    description = string
    ingress = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
  }))
}

variable "ami" {
  type    = string
  default = "ami-0c02fb55956c7d316" # Amazon Linux 2
}

variable "ec2_instances" {
  description = "Map of EC2 instances"
  type = map(object({
    name          = string
    instance_type = string
    subnet_key    = string
  }))
}
