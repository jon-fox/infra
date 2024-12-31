provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    key    = "terraform/sqs/terraform.tfstate"  # Path inside the bucket to store the state
    region = "us-east-1"  # AWS region, e.g., us-west-2
  }
}

# data "aws_ssm_parameter" "vpc_id" {
#   name = "/account/vpc_id"  
# }

resource "aws_sqs_queue" "sqs_queue" {
  # name                      = "audio-processing-queue.fifo"
  name                      = "audio-processing-queue"
  # fifo_queue                = true
  fifo_queue                = false
  visibility_timeout_seconds = 3600 # how long the message is invisible after it is being processed
  message_retention_seconds  = 86400 # retention
  delay_seconds              = 0 # delay of message visibility to consumers
  max_message_size           = 262144
  receive_wait_time_seconds  = 10 # how long sqs waits to return response, > 0 is long polling
  # content_based_deduplication = true # prevents dupe messages
}

resource "aws_sqs_queue" "sqs_scaling_queue" {
  # name                      = "audio-processing-queue.fifo"
  name                      = "ec2-scaling-queue"
  # fifo_queue                = true
  fifo_queue                = false
  visibility_timeout_seconds = 3600 # how long the message is invisible after it is being processed
  message_retention_seconds  = 86400 # retention
  delay_seconds              = 0 # delay of message visibility to consumers
  max_message_size           = 262144
  receive_wait_time_seconds  = 10 # how long sqs waits to return response, > 0 is long polling
  # content_based_deduplication = true # prevents dupe messages
}

resource "aws_ssm_parameter" "sqs_queue_url" {
  name  = "/sqs/audio_processing/url"
  type  = "String"
  value = aws_sqs_queue.sqs_queue.id
}

resource "aws_ssm_parameter" "sqs_queue_name" {
  name  = "/sqs/audio_processing/name"
  type  = "String"
  value = aws_sqs_queue.sqs_queue.name
}

resource "aws_ssm_parameter" "scaling_sqs_queue_url" {
  name  = "/sqs/scaling/url"
  type  = "String"
  value = aws_sqs_queue.sqs_scaling_queue.id
}

resource "aws_ssm_parameter" "scaling_sqs_queue_name" {
  name  = "/sqs/scaling/name"
  type  = "String"
  value = aws_sqs_queue.sqs_scaling_queue.name
}