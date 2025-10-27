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
      description = optional(string)
    }))
  }))
}

variable "ami" {
  type    = string
  default = "ami-0c02fb55956c7d316" # Amazon Linux 2 (update per region)
}


variable "ec2_instances" {
  description = "Map of EC2 instances (keyed so we can attach to TGs by same key)"
  type = map(object({
    name          = string
    instance_type = string
    subnet_key    = string
  }))
}

variable "alb_name" {
  type    = string
  default = "linux-alb"
}

variable "target_groups" {
  description = "Map of target groups"
  type = map(object({
    name                = string
    port                = number
    protocol            = string
    health_check_path   = optional(string)
    health_check_protocol = optional(string)
    matcher             = optional(string)
    interval            = optional(number)
    timeout             = optional(number)
    healthy_threshold   = optional(number)
    unhealthy_threshold = optional(number)
  }))
}

variable "path_map" {
  description = "Map of listener rules with path -> target group key"
  type = map(object({
    path     = string
    priority = number
    tg_key   = string
  }))
}
