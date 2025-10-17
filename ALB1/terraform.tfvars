region = "us-east-1"

subnets = {
  subnet1 = {
    name = "public-subnet-1"
    cidr = "10.0.1.0/24"
    az   = "us-east-1a"
  }
  subnet2 = {
    name = "public-subnet-2"
    cidr = "10.0.2.0/24"
    az   = "us-east-1b"
  }
}

security_groups = {
  ec2 = {
    name        = "ec2-sg"
    description = "Allow SSH and HTTP"
    ingress = [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "SSH access"
      },
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP access"
      }
    ]
  }

  alb = {
    name        = "alb-sg"
    description = "Allow HTTP inbound"
    ingress = [
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP access"
      }
    ]
  }
}

ec2_instances = {
  ec2-1 = {
    name          = "linux-apache-1"
    instance_type = "t2.micro"
    subnet_key    = "subnet1"
  }

  ec2-2 = {
    name          = "linux-apache-2"
    instance_type = "t2.micro"
    subnet_key    = "subnet2"
  }
}
