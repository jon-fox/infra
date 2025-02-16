provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    key    = "terraform/lambda_edge/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_iam_role" "lambda_edge_role" {
  name = "lambda_edge_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",        
            "edgelambda.amazonaws.com"     # Lambda@Edge
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_edge_policy" {
  name       = "lambda_edge_policy"
  roles      = [aws_iam_role.lambda_edge_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_ssm_parameter" "cloudfront_distribution_id" {
  name = "/cloudfront/distribution/id"
}

resource "aws_lambda_function" "redirect_index" {
  function_name    = "redirect-html"
  role             = aws_iam_role.lambda_edge_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  filename         = "lambda_edge.zip"
  source_code_hash = filebase64sha256("lambda_edge.zip")
  publish          = true
}
