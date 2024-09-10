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
