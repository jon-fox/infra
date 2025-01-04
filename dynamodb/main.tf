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

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Environment = "production"
    Project     = "PodcastAdFreeService"
    Description = "Feeds for each user"
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

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Environment = "production"
    Project     = "PodcastAdFreeService"
    Description = "Episodes with metadata"
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

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Environment = "production"
    Project     = "PodcastAdFreeService"
    Description = "Episodes in each feed linking table"
  }
}

resource "aws_dynamodb_table" "users_table" {
  name           = "UsersTable"
  billing_mode   = "PAY_PER_REQUEST" # On-demand scaling
  hash_key       = "username"

  attribute {
    name = "username"
    type = "S" # String
  }

  # Enable server-side encryption for security
  server_side_encryption {
    enabled = true
  }

  # Optional: Configure TTL (e.g., for temporary data like session expiration)
  ttl {
    attribute_name = "ttl"
    enabled        = false
  }

  lifecycle {
    prevent_destroy = true
  }

  # Tags for organization
  tags = {
    Environment = "production"
    Team        = "PodcastAdFreeService"
    Description = "User account data"
  }
}

