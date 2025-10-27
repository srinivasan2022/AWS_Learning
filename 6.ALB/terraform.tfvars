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
    description = "Allow SSH and HTTP to EC2"
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
    description = "Allow HTTP inbound to ALB"
    ingress = [
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP"
      }
    ]
  }
}

ec2_instances = {
  Amazon = {
    name          = "Amazon"
    instance_type = "t2.micro"
    subnet_key    = "subnet1"
  }

  Flipkart = {
    name          = "Flipkart"
    instance_type = "t2.micro"
    subnet_key    = "subnet2"
  }
}


target_groups = {
  Amazon = {
    name     = "Amazon-tg"
    port     = 80
    protocol = "HTTP"
    health_check_path = "/Amazon"
    matcher = "200"
  }

  Flipkart = {
    name     = "Flipkart-tg"
    port     = 80
    protocol = "HTTP"
    health_check_path = "/Flipkart"
    matcher = "200"
  }
}

path_map = {
  Amazon = {
    path     = "/Amazon"
    priority = 10
    tg_key   = "Amazon"
  }

  Flipkart = {
    path     = "/Flipkart"
    priority = 20
    tg_key   = "Flipkart"
  }
}
