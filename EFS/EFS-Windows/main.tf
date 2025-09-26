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
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
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

  # NFS for EFS
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- EFS ----------
resource "aws_efs_file_system" "my_efs" {
  creation_token = "windows-efs"
  tags = { Name = "windows-efs" }
}

# ---------- EFS Mount Target ----------
resource "aws_efs_mount_target" "mt1" {
  file_system_id  = aws_efs_file_system.my_efs.id
  subnet_id       = aws_subnet.subnet1.id
  security_groups = [aws_security_group.windows_sg.id]
}

# ---------- Windows EC2 ----------
resource "aws_instance" "windows_ec2" {
  ami                    = "ami-04b4f1a9cf54c11d0" # Windows Server 2022
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.windows_sg.id]
  key_name               = "windows-key"

  user_data = <<-EOF
    <powershell>
    # Enable NFS Client
    Install-WindowsFeature NFS-Client

    # Create mount directory
    New-Item -Path "E:\" -ItemType Directory -Force

    # Mount EFS (replace DNS name with your EFS DNS)
    $efs_dns = "${aws_efs_file_system.my_efs.dns_name}"
    mount -o anon \\$efs_dns\ e:\
    </powershell>
  EOF

  tags = {
    Name = "windows-ec2-efs"
  }
}

# ---------- Output ----------
output "efs_dns_name" {
  value = aws_efs_file_system.my_efs.dns_name
}
