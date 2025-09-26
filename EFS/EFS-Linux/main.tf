provider "aws" {
  region = "us-east-1"
}

# ---------- VPC ----------
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# ---------- Subnets ----------
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

# ---------- Security Group for EFS ----------
resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Allow NFS access to EFS"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # allow VPC traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- EFS File System ----------
resource "aws_efs_file_system" "my_efs" {
  creation_token = "my-efs-tf"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"  # Optional: move to Infrequent Access
  }

  tags = {
    Name = "my-efs"
  }
}

# ---------- EFS Mount Targets ----------
resource "aws_efs_mount_target" "mt1" {
  file_system_id  = aws_efs_file_system.my_efs.id
  subnet_id       = aws_subnet.subnet1.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "mt2" {
  file_system_id  = aws_efs_file_system.my_efs.id
  subnet_id       = aws_subnet.subnet2.id
  security_groups = [aws_security_group.efs_sg.id]
}

# ---------- Linux EC2 Example to Mount EFS ----------
resource "aws_instance" "linux_ec2" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.efs_sg.id]
  key_name               = "linux-key"  # Assume key already exists

  user_data = <<-EOF
    #!/bin/bash
    yum install -y amazon-efs-utils
    mkdir -p /mnt/efs
    mount -t efs ${aws_efs_file_system.my_efs.id}:/ /mnt/efs
    echo "${aws_efs_file_system.my_efs.id}:/ /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab
  EOF

  tags = {
    Name = "linux-ec2-efs"
  }
}

# ---------- Output EFS ID ----------
output "efs_id" {
  value = aws_efs_file_system.my_efs.id
}


# VPC & Subnets → Network foundation for EC2 & EFS.

# Security Group → Allows NFS access to EC2.

# EFS File System → The network storage.

# Mount Targets → Required per AZ to connect EC2.

# EC2 Instance + User Data → Mounts the EFS automatically.

# Output → Shows EFS ID for reference.
