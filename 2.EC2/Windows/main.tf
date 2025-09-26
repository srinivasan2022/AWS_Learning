# ---------- Provider ----------
provider "aws" {
  region = "us-east-1" # Change to your region
}

# ---------- VPC ----------
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}

# ---------- Subnet ----------
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "my-subnet"
  }
}

# ---------- Internet Gateway ----------
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

# ---------- Route Table ----------
resource "aws_route_table" "my_rtb" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "my-rtb"
  }
}

# ---------- Route Table Association ----------
resource "aws_route_table_association" "my_rtb_assoc" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_rtb.id
}

# ---------- Security Group ----------
resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "windows-sg"

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # RDP access from anywhere (not recommended for prod!)
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "windows-sg"
  }
}

# ---------- Windows EC2 Instance ----------
resource "aws_instance" "windows_ec2" {
  ami                    = "ami-0e3c2921641a4a215" # Windows Server 2022 Base in us-east-1 (check region)
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "windows-ec2"
  }
}

# Notes:
# IGW = gives your VPC internet connectivity

# Route Table = defines where subnet traffic goes

# Route Table Association = links subnet → route table

# Security Group = controls who can connect to the instance

