provider "aws" {
  region = var.region
}

# Create an ECR repository
resource "aws_ecr_repository" "app_repo" {
  name = "app-ecr-repo"
}

