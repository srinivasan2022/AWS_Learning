provider "aws" {
  region = "us-east-1"
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
resource "aws_security_group" "windows_sg" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "windows-sg"

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
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
  ami                    = "ami-04b4f1a9cf54c11d0" # Windows Server 2022 Base (us-east-1)
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.windows_sg.id]
  associate_public_ip_address = true

  # Encode PowerShell script as base64
  user_data_base64 = base64encode(<<-EOF
    <powershell>
      Install-WindowsFeature -name Web-Server -IncludeManagementTools
      Set-Content -Path "C:\\inetpub\\wwwroot\\index.html" -Value "<h1>Hello from Terraform Windows IIS!</h1>"
      New-NetFirewallRule -DisplayName "Allow-HTTP" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow
      New-NetFirewallRule -DisplayName "Allow-HTTPS" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow
      Start-Service W3SVC
    </powershell>
  EOF
  )

  tags = {
    Name = "windows-iis-ec2"
  }
}

# ---------- Output Public IP ----------
output "windows_ec2_public_ip" {
  value = aws_instance.windows_ec2.public_ip
}
