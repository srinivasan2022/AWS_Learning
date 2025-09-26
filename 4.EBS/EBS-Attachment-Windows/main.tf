provider "aws" {
  region = "us-east-1"
}

# ---------- VPC ----------
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# ---------- Subnet ----------
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# ---------- Security Group ----------
resource "aws_security_group" "windows_sg" {
  vpc_id = aws_vpc.my_vpc.id

  # RDP
  ingress {
    from_port   = 3389
    to_port     = 3389
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


# ---------- Windows EC2 Instance ----------
resource "aws_instance" "windows_ec2" {
  ami                    = "ami-04b4f1a9cf54c11d0" # Windows Server 2022
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.windows_sg.id]

  tags = {
    Name = "windows-ec2"
  }
}

# ---------- EBS Volume ----------
resource "aws_ebs_volume" "windows_volume" {
  availability_zone = "us-east-1a"
  size              = 20
  type              = "gp3"

  tags = {
    Name = "windows-ebs"
  }
}

# ---------- Attach EBS Volume to Windows EC2 ----------
resource "aws_volume_attachment" "windows_attach" {
  device_name = "xvdf"  # Windows will see it as a new disk
  volume_id   = aws_ebs_volume.windows_volume.id
  instance_id = aws_instance.windows_ec2.id
}
