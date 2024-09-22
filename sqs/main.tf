provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    key    = "terraform/ec2/terraform.tfstate"  # Path inside the bucket to store the state
    region = "us-east-1"  # AWS region, e.g., us-west-2
  }
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/account/vpc_id"  
}
