provider "aws" {
  region = var.region
}

# -----------------------------------
# VPC
# -----------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "MyVPC" }
}

# -----------------------------------
# INTERNET GATEWAY
# -----------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "Main-IGW" }
}

# -----------------------------------
# PUBLIC SUBNET 1 (VM1)
# -----------------------------------
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.az1
  map_public_ip_on_launch = true

  tags = { Name = "Subnet-1" }
}

# -----------------------------------
# PUBLIC SUBNET 2 (VM2)
# -----------------------------------
resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.az2
  map_public_ip_on_launch = true

  tags = { Name = "Subnet-2" }
}

# -----------------------------------
# ROUTE TABLE + ROUTE TO IGW
# -----------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "Public-RouteTable" }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

# -----------------------------------
# SECURITY GROUP
# -----------------------------------
resource "aws_security_group" "web_sg" {
  name        = "multiport-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------
# EC2 INSTANCE 1 — Port 80
# -----------------------------------
resource "aws_instance" "vm1" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet1.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = var.keypair

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              echo "<h1>VM1 website running on port 80</h1>" > /var/www/html/index.html
              systemctl enable httpd
              systemctl start httpd
              EOF

  tags = { Name = "VM1-Port80" }
}

# -----------------------------------
# EC2 INSTANCE 2 — Port 81
# -----------------------------------
resource "aws_instance" "vm2" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet2.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = var.keypair

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              echo "Listen 81" >> /etc/httpd/conf/httpd.conf
              echo "<h1>VM2 website running on port 81</h1>" > /var/www/html/index.html
              systemctl enable httpd
              systemctl restart httpd
              EOF

  tags = { Name = "VM2-Port81" }
}

# -----------------------------------
# NETWORK LOAD BALANCER
# -----------------------------------
resource "aws_lb" "nlb" {
  name               = "two-vm-nlb"
  load_balancer_type = "network"
  internal           = false
  subnets            = [
    aws_subnet.subnet1.id,
    aws_subnet.subnet2.id
  ]
}

# -----------------------------------
# TARGET GROUPS
# -----------------------------------
resource "aws_lb_target_group" "tg80" {
  name        = "tg-port80"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_target_group" "tg81" {
  name        = "tg-port81"
  port        = 81
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
}

# Attach VM1 → TG80
resource "aws_lb_target_group_attachment" "vm1_attach" {
  target_group_arn = aws_lb_target_group.tg80.arn
  target_id        = aws_instance.vm1.id
  port             = 80
}

# Attach VM2 → TG81
resource "aws_lb_target_group_attachment" "vm2_attach" {
  target_group_arn = aws_lb_target_group.tg81.arn
  target_id        = aws_instance.vm2.id
  port             = 81
}

# -----------------------------------
# LISTENERS
# -----------------------------------
resource "aws_lb_listener" "listener80" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg80.arn
  }
}

resource "aws_lb_listener" "listener81" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 81
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg81.arn
  }
}

# -----------------------------------
# OUTPUT
# -----------------------------------
output "nlb_dns" {
  value = aws_lb.nlb.dns_name
}
