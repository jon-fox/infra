provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    key    = "terraform/s3/terraform.tfstate"  # Path inside the bucket to store the state
    region = "us-east-1"  # AWS region, e.g., us-west-2
  }
}

data "aws_iam_role" "existing_role" {
  name = "docker-external-app"
}

data "aws_iam_role" "existing_role_lambda" {
  name = "lambda_execution_role"
}

data "aws_ssm_parameter" "account_id" {
  name = "/account/account_id"
}

data "aws_ssm_parameter" "config_bucket_name" {
  name = "/account/config_bucket_name"
}

data "aws_ssm_parameter" "storage_bucket_name" {
  name = "/app/app_storage_bucket"
}

data "aws_ssm_parameter" "alb_url" {
  name = "/app/alb_url"
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = data.aws_ssm_parameter.config_bucket_name.value
}

resource "aws_s3_bucket" "app_storage_bucket" {
  bucket = data.aws_ssm_parameter.storage_bucket_name.value
}

resource "aws_s3_bucket_policy" "app_bucket_policy" {
  bucket = aws_s3_bucket.app_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_iam_role.existing_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.app_bucket.arn}",
          "${aws_s3_bucket.app_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Policy to allow access to the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
            "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.app_bucket.arn}",
          "${aws_s3_bucket.app_storage_bucket.arn}"
          ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.app_bucket.arn}/*",
          "${aws_s3_bucket.app_storage_bucket.arn}/*"
          ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_access_policy" {
  role       = data.aws_iam_role.existing_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_s3_access_policy_lambda" {
  role       = data.aws_iam_role.existing_role_lambda.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for accessing S3 bucket"
}

# Step 2: Update S3 Bucket Policy for CloudFront Access
resource "aws_s3_bucket_policy" "app_storage_bucket_policy_cloudfront" {
  bucket = aws_s3_bucket.app_storage_bucket.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": {
        "Sid": "AllowCloudFrontServicePrincipalReadOnly",
        "Effect": "Allow",
        "Principal": {
            "Service": "cloudfront.amazonaws.com"
        },
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.app_storage_bucket.arn}/*",
        "Condition": {
            "StringEquals": {
                "AWS:SourceArn": "arn:aws:cloudfront::${data.aws_ssm_parameter.account_id.value}:distribution/${aws_cloudfront_distribution.cdn.id}"
            }
        }
    }
} )
}

# Step 3: Create CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.app_storage_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.app_storage_bucket.bucket}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.app_storage_bucket.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_ssm_parameter" "cloudfront_distribution_id" {
  name  = "/cloudfront/distribution/id"
  type  = "String"
  value = aws_cloudfront_distribution.cdn.id
}

resource "aws_ssm_parameter" "cloudfront_distribution_url" {
  name  = "/cloudfront/distribution/url"
  type  = "String"
  value = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}