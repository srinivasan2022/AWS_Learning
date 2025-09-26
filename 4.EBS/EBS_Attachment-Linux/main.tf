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
resource "aws_security_group" "linux_sg" {
  vpc_id = aws_vpc.my_vpc.id

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


# ---------- Linux EC2 Instance ----------
resource "aws_instance" "linux_ec2" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2 in us-east-1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.linux_sg.id]

  tags = {
    Name = "linux-ec2"
  }
}

# ---------- EBS Volume ----------
resource "aws_ebs_volume" "my_volume" {
  availability_zone = "us-east-1a"
  size              = 10          # size in GB
  type              = "gp3"       # general purpose SSD
  tags = {
    Name = "my-ebs-volume"
  }
}

# ---------- Attach EBS Volume to EC2 ----------
resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdf"           # Linux device name
  volume_id   = aws_ebs_volume.my_volume.id
  instance_id = aws_instance.linux_ec2.id
}
