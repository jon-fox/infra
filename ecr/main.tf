provider "aws" {
  region = var.region
}

# Create an ECR repository
resource "aws_ecr_repository" "app_repo" {
  name = "app-ecr-repo"
}

data "aws_iam_role" "existing_role" {
  name = "docker-external-app"
}

resource "aws_iam_policy" "ecr_policy" {
  name        = "ECRAccessPolicy"
  description = "Policy to allow ECR access"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  role       = data.aws_iam_role.existing_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}