provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    key    = "terraform/lambda_edge/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
}

resource "aws_iam_policy_attachment" "lambda_edge_policy" {
  name       = "lambda_edge_policy"
  roles      = [data.aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_ssm_parameter" "cloudfront_distribution_id" {
  name = "/cloudfront/distribution/id"
}

resource "aws_lambda_function" "redirect_index" {
  function_name    = "redirect-html"
  role             = data.aws_iam_role.lambda_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  filename         = "lambda_edge.zip"
  source_code_hash = filebase64sha256("lambda_edge.zip")
  publish          = true
}
