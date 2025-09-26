provider "aws" {
  region = "us-east-1"
}

# Random suffix to ensure bucket name is globally unique
resource "random_id" "rand" {
  byte_length = 4
}

# ---------- S3 Bucket ----------
resource "aws_s3_bucket" "static_site" {
  bucket = "my-terraform-demo-bucket-${random_id.rand.hex}"

  tags = {
    Name        = "static-website"
    Environment = "Dev"
  }
}

# ---------- Enable Static Website Hosting ----------
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# ---------- Public Access Block (disable to allow website hosting) ----------
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ---------- Make Objects Public ----------
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })
}

# ---------- Upload Website Files ----------
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.static_site.bucket
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.static_site.bucket
  key          = "error.html"
  source       = "error.html"
  content_type = "text/html"
}

# ---------- Output Website Endpoint ----------
output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}

# aws_s3_bucket	--> Create the S3 bucket
# aws_s3_bucket_website_configuration -->Enable static website hosting, set index & error pages
# aws_s3_bucket_public_access_block	--> Allow public access for the website (AWS blocks public access to buckets by default)
# aws_s3_bucket_policy --> Make all files readable by the public
# aws_s3_object -->	Upload local files to the S3 bucket


# Grants public read access to all objects in the bucket.
# Principal = "*" → everyone (public).
# Action = "s3:GetObject" → allows reading objects (HTTP GET).
# Resource = bucket ARN + /* → applies to all files in the bucket.
# Without this, visitors cannot see your website even if hosting is enabled.
