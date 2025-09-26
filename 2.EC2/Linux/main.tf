# ---------- Provider ----------
provider "aws" {
  region = "us-east-1"
}

# ---------- VPC ----------
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc1"
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
resource "aws_security_group" "linux_sg" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "linux-sg"

  ingress {
    from_port   = 22   # SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ for demo only; restrict to your IP in real usage
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "linux-sg"
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

# ---------- Output Public IP ----------
output "linux_ec2_public_ip" {
  value = aws_instance.linux_ec2.public_ip
}
