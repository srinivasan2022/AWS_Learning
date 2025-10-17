terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.region
}

# -------------------------------
# VPC
# -------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# -------------------------------
# Subnets (Map)
# -------------------------------
resource "aws_subnet" "public" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = each.value.name
  }
}

# -------------------------------
# Internet Gateway & Routing
# -------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

# -------------------------------
# Route Table Associations (Map)
# -------------------------------
resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------------------
# Security Groups (Map)
# -------------------------------
resource "aws_security_group" "sg" {
  for_each = var.security_groups

  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = each.value.name
  }
}

# -------------------------------
# EC2 Instances using map variable
# -------------------------------
resource "aws_instance" "linux_ec2" {
  for_each = var.ec2_instances

  ami                    = var.ami
  instance_type          = each.value.instance_type
  subnet_id              = aws_subnet.public[each.value.subnet_key].id
  vpc_security_group_ids = [aws_security_group.sg["ec2"].id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>Hello from Terraform Linux Apache! $(hostname -f)</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = each.value.name
  }
}

# -------------------------------
# ALB
# -------------------------------
resource "aws_lb" "app_lb" {
  name               = "linux-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg["alb"].id]
  subnets            = [for s in aws_subnet.public : s.id]

  tags = {
    Name = "linux-alb"
  }
}

# -------------------------------
# Target Group
# -------------------------------
resource "aws_lb_target_group" "alb_tg" {
  name     = "my-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "my-alb-tg"
  }
}

# -------------------------------
# Target Group Attachment
# -------------------------------
resource "aws_lb_target_group_attachment" "tg_attach" {
  for_each = aws_instance.linux_ec2

  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = each.value.id
  port             = 80
}

# -------------------------------
# Listener
# -------------------------------
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

# -------------------------------
# Outputs
# -------------------------------
output "alb_dns_name" {
  value = aws_lb.app_lb.dns_name
}

output "ec2_public_ips" {
  value = { for k, inst in aws_instance.linux_ec2 : k => inst.public_ip }
}
