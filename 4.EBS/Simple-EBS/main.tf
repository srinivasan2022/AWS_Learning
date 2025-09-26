provider "aws" {
  region = "us-east-1"
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