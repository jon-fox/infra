provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    key    = "terraform/scaling_lambda/terraform.tfstate"  # Path inside the bucket to store the state
    region = "us-east-1"  # AWS region, e.g., us-west-2
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_scaling_role" {
  name = "lambda_scaling_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Scaling
resource "aws_iam_policy" "lambda_scaling_policy" {
  name        = "lambda_scaling_policy"
  description = "Policy for scaling Auto Scaling group via Lambda"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:DescribeAutoScalingGroups"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "lambda_scaling_policy_attachment" {
  role       = aws_iam_role.lambda_scaling_role.name
  policy_arn = aws_iam_policy.lambda_scaling_policy.arn
}

data "aws_ssm_parameter" "asg_name" {
  name = "/asg/name"
}

# Lambda Function
resource "aws_lambda_function" "scaling_function" {
  filename         = "lambda_scaling.zip"  # Zip file containing the Lambda function code
  function_name    = "scaling_function"
  role             = aws_iam_role.lambda_scaling_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = filebase64sha256("lambda_scaling.zip")
  
  environment {
    variables = {
      AUTOSCALING_GROUP_NAME = data.aws_ssm_parameter.asg_name.value
    }
  }
}

# SNS Topic
resource "aws_sns_topic" "scaling_topic" {
  name = "scaling-topic"
}

# SNS Subscription for Lambda
resource "aws_sns_topic_subscription" "sns_lambda_subscription" {
  topic_arn = aws_sns_topic.scaling_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.scaling_function.arn

  depends_on = [
    aws_lambda_function.scaling_function
  ]
}

# SNS Subscription for SMS
resource "aws_sns_topic_subscription" "sms_subscription" {
  topic_arn = aws_sns_topic.scaling_topic.arn
  protocol  = "sms"
  endpoint  = var.phone_number
}

# Lambda Permission to Invoke from SNS
resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scaling_function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.scaling_topic.arn
}
