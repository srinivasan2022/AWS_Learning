variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ami" {
  type    = string
  default = "ami-0c02fb55956c7d316" # Amazon Linux 2
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "keypair" {
  type = string
}

variable "az1" {
  type    = string
  default = "us-east-1a"
}

variable "az2" {
  type    = string
  default = "us-east-1b"
}
