provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    key    = "terraform/scaling_lambda/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ssm_parameter" "sqs_name" {
  name = "/sqs/scaling/name"
}

data "aws_ssm_parameter" "asg_name" {
  name = "/asg/name"
}

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
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "sns:Publish",
          "sns:ListTopics",
          "sns:Subscribe",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_scaling_policy_attachment" {
  role       = aws_iam_role.lambda_scaling_role.name
  policy_arn = aws_iam_policy.lambda_scaling_policy.arn
}

resource "aws_lambda_function" "scaling_function_up" {
  filename         = "${path.module}/src/lambda_scaling_up.zip"
  function_name    = "scaling_function_up"
  role             = aws_iam_role.lambda_scaling_role.arn
  handler          = "lambda_scaling_up.lambda_handler"
  runtime          = "python3.11"
  timeout          = 20 # lambda contains a 10 second wait
  source_code_hash = filebase64sha256("${path.module}/src/lambda_scaling_up.zip")
  
  environment {
    variables = {
      AUTOSCALING_GROUP_NAME = data.aws_ssm_parameter.asg_name.value
    }
  }
}

resource "aws_lambda_function" "scaling_function_down" {
  filename         = "${path.module}/src/lambda_scaling_down.zip"
  function_name    = "scaling_function_down"
  role             = aws_iam_role.lambda_scaling_role.arn
  handler          = "lambda_scaling_down.lambda_handler"
  runtime          = "python3.11"
  timeout          = 20 # lambda contains a 10 second wait
  source_code_hash = filebase64sha256("${path.module}/src/lambda_scaling_down.zip")
  
  environment {
    variables = {
      AUTOSCALING_GROUP_NAME = data.aws_ssm_parameter.asg_name.value
    }
  }
}

data "aws_sqs_queue" "scaling_queue" {
  name = data.aws_ssm_parameter.sqs_name.value
}

#eventbridge for scale down
resource "aws_cloudwatch_event_rule" "every_minute" {
  name                = "every_minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "invoke_lambda_scaling_down" {
  rule      = aws_cloudwatch_event_rule.every_minute.name
  target_id = "invoke_lambda_scaling_down"
  arn       = aws_lambda_function.scaling_function_down.arn
}

resource "aws_lambda_permission" "allow_eventbridge_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scaling_function_down.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_minute.arn
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn =  data.aws_sqs_queue.scaling_queue.arn
  function_name    = aws_lambda_function.scaling_function_up.arn
  batch_size       = 1
  enabled          = true
}
