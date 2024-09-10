provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    key    = "terraform/parameters/terraform.tfstate"  # Path inside the bucket to store the state
    region = "us-east-1"  # AWS region, e.g., us-west-2
  }
}

resource "aws_kms_key" "param_store_kms_key" {
  description = "KMS key for SSM parameters"
  policy      = <<POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "AWS": [
              "arn:aws:iam::${var.aws_account}:root",
              "arn:aws:iam::${var.aws_account}:user/iamadmin",
              "arn:aws:iam::${var.aws_account}:role/terraform-dev"
            ]
          },
          "Action": "kms:*",
          "Resource": "*"
        }
      ]
    }
    POLICY
}

locals {
  taddy_credentials = {
    taddy_user_id = var.taddy_user_id
    taddy_api_key = var.taddy_api_key
  }

  postgres_credentials = {
    postgres_ip   = var.postgres_ip
    postgres_auth = var.postgres_auth
  }

  backblaze_credentials = {
    backblaze_key_name     = var.backblaze_key_name
    backblaze_key_id       = var.backblaze_key_id
    backblaze_api_key      = var.backblaze_api_key
    backblaze_bucket_name  = var.backblaze_bucket_name
    backblaze_endpoint     = var.backblaze_endpoint
    backblaze_region       = var.backblaze_region
    backblaze_cdn_url      = var.backblaze_cdn_url
  }
}

resource "aws_ssm_parameter" "aws_account_id" {
  name     = "/account/account_id"
  type     = "String"
  value    = var.aws_account
}

resource "aws_ssm_parameter" "openai_api_key" {
  name     = "/openai/api_key"
  type     = "SecureString"
  value    = var.openai_api_key
  key_id   = aws_kms_key.param_store_kms_key.arn
}

resource "aws_ssm_parameter" "taddy_credentials" {
  name     = "/taddy/credentials"
  type     = "SecureString"
  value    = jsonencode(local.taddy_credentials)
  key_id   = aws_kms_key.param_store_kms_key.arn
}

resource "aws_ssm_parameter" "cloudflare_credentials" {
  name     = "/cloudflare/credentials"
  type     = "SecureString"
  value    = var.cloudflare_api_token
  key_id   = aws_kms_key.param_store_kms_key.arn
}

resource "aws_ssm_parameter" "postgres_credentials" {
  name     = "/postgres/credentials"
  type     = "SecureString"
  value    = jsonencode(local.postgres_credentials)
  key_id   = aws_kms_key.param_store_kms_key.arn
}

resource "aws_ssm_parameter" "backblaze_credentials" {
  name     = "/backblaze/credentials"
  type     = "SecureString"
  value    = jsonencode(local.backblaze_credentials)
  key_id   = aws_kms_key.param_store_kms_key.arn
}

