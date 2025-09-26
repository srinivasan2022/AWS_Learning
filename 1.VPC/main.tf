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

# enable_dns_support = true 
# enable_dns_hostnames = true
# ✅ If your subnet will be public and you need internet access with public DNS names → both should be true.
# ❌ If your VPC is completely private (no internet access, only internal communication) → you can leave the defaults (enable_dns_support = true, enable_dns_hostnames = false).

# map_public_ip_on_launch = true
# ✅ If you want instances in this subnet to get a public IP automatically → set to true.
# ❌ If you want instances to only have private IPs (no internet access) → set to false.