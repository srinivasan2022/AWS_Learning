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
# Subnets (map)
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
# Internet Gateway & Route Table
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

# Associate route table to every public subnet created
resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------------------
# Security Groups (map)
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
      description = lookup(ingress.value, "description", null)
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
# EC2 Instances (map)
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
    mkdir /var/www/html/${each.value.name}
    echo "<h1>Hello from ${each.value.name} - $(hostname -f)</h1>" > /var/www/html/${each.value.name}/index.html
  EOF

  tags = {
    Name = each.value.name
  }
}

# -------------------------------
# ALB Security Group used by ALB
# -------------------------------
# created via security_groups map (key = "alb")

# -------------------------------
# Application Load Balancer (needs at least 2 subnets)
# -------------------------------
resource "aws_lb" "app_lb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg["alb"].id]
  subnets            = [for s in aws_subnet.public : s.id]

  tags = {
    Name = var.alb_name
  }
}

# -------------------------------
# Target Groups (map)
# -------------------------------
resource "aws_lb_target_group" "tgs" {
  for_each = var.target_groups

  name     = each.value.name
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/${each.value.health_check_path}"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = each.value.name
  }
}

# -------------------------------
# Attach EC2 Instances to their respective Target Group
# (assumes target group key matches EC2 map key)
# -------------------------------
resource "aws_lb_target_group_attachment" "tg_attach" {
  for_each = aws_instance.linux_ec2

  target_group_arn = aws_lb_target_group.tgs[each.key].arn
  target_id        = each.value.id
  port             = 80
}

# -------------------------------
# Listener (HTTP:80)
# -------------------------------
# ----------------------------
# ALB Listener with Weighted Target Groups
# ----------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.tgs["Amazon"].arn
        weight = 50
      }

      target_group {
        arn    = aws_lb_target_group.tgs["Flipkart"].arn
        weight = 50
      }

      stickiness {
        enabled  = false
        duration = 1
      }
    }
  }
}


# -------------------------------
# Listener Rules: path-based routing
# -------------------------------
# resource "aws_lb_listener_rule" "path_rules" {
#   for_each = var.path_map

#   listener_arn = aws_lb_listener.http.arn
#   priority     = each.value.priority

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.tgs[each.value.tg_key].arn
#   }

#   condition {
#     path_pattern {
#       values = [each.value.path]
#     }
#   }
# }

# -------------------------------
# Outputs
# -------------------------------
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.app_lb.dns_name
}

output "ec2_public_ips" {
  description = "Map of EC2 public IPs"
  value       = { for k, inst in aws_instance.linux_ec2 : k => inst.public_ip }
}

output "target_group_arns" {
  value = { for k, tg in aws_lb_target_group.tgs : k => tg.arn }
}
