provider "aws" {
  region = "us-east-1"
}

# Random suffix to ensure bucket name is globally unique
resource "random_id" "rand" {
  byte_length = 4
}

# ---------- S3 Bucket ----------
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-terraform-demo-bucket-${random_id.rand.hex}"

  tags = {
    Name        = "my-s3-bucket"
    Environment = "Dev"
  }
}

# ---------- S3 Bucket ACL ----------
# resource "aws_s3_bucket_acl" "my_bucket_acl" {
#   bucket = aws_s3_bucket.my_bucket.id
#   acl    = "private"
# }

# ---------- Output ----------
output "bucket_name" {
  value = aws_s3_bucket.my_bucket.bucket
}
