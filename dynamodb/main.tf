provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    key    = "terraform/dynamodb/terraform.tfstate"  # Path inside the bucket to store the state
    region = "us-east-1"  
  }
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/account/vpc_id"  
}

resource "aws_dynamodb_table" "user_feeds" {
  name           = "UserFeeds"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"    # Partition key
  range_key      = "feed_id"    # Sort key

  attribute {
    name = "user_id"
    type = "S"  # String
  }

  attribute {
    name = "feed_id"
    type = "S"  # String
  }

  tags = {
    Environment = "production"
    Project     = "PodcastAdFreeService"
  }
}

resource "aws_dynamodb_table" "episodes" {
  name           = "Episodes"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "episode_id"  # Partition key

  attribute {
    name = "episode_id"
    type = "S"  # String
  }

  tags = {
    Environment = "production"
    Project     = "PodcastAdFreeService"
  }
}

resource "aws_dynamodb_table" "feed_episodes" {
  name           = "FeedEpisodes"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "feed_id"      # Partition key
  range_key      = "episode_id"   # Sort key

  attribute {
    name = "feed_id"
    type = "S"  # String
  }

  attribute {
    name = "episode_id"
    type = "S"  # String
  }

  tags = {
    Environment = "production"
    Project     = "PodcastAdFreeService"
  }
}

