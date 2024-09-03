provider "aws" {
  region = "us-east-1"  # Change to your preferred AWS region
}

resource "random_password" "rds_master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&()*+,-.:;<=>?[]^_`{|}~"
}

data "aws_ssm_parameter" "rds_username" {
  name = "/rds/master_username"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/account/vpc_id"  
}

data "aws_ssm_parameter" "rds_db_name" {
  name = "/rds/db_name"
}

resource "aws_secretsmanager_secret" "rds_master_secret" {
  name = "rds-master-password"
}

resource "aws_secretsmanager_secret_version" "rds_master_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_master_secret.id
  secret_string = jsonencode({
    username = data.aws_ssm_parameter.rds_username.value,
    password = random_password.rds_master_password.result
  })
}

data "aws_security_group" "ec2_security_group" {
  name = "ec2_launch_template_sg"
}

data "http" "my_ip" {
  url = "http://checkip.amazonaws.com/"
}


resource "aws_security_group" "rds_security_group" {
  name        = "rds-sg"
  description = "Allow EC2 access to RDS"

  vpc_id = data.aws_ssm_parameter.vpc_id.value

  ingress {
    description = "PostgreSQL access from EC2"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      data.aws_security_group.ec2_security_group.id
    ]
  }

  ingress {
    description = "PostgreSQL access from my IP"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [
      "${chomp(data.http.my_ip.body)}/32"
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "rds_postgres" {
  identifier              = "managed-postgres"
  instance_class          = "db.t4g.micro"
  engine                  = "postgres"
  engine_version          = "16"
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp2"
  db_name                 = data.aws_ssm_parameter.rds_db_name.value
  username                = jsondecode(aws_secretsmanager_secret_version.rds_master_secret_version.secret_string)["username"]
  password                = jsondecode(aws_secretsmanager_secret_version.rds_master_secret_version.secret_string)["password"]
  vpc_security_group_ids  = [aws_security_group.rds_security_group.id]
  iam_database_authentication_enabled = true
  skip_final_snapshot     = true
  publicly_accessible     = true
  backup_retention_period = 7
  multi_az                = false
  storage_encrypted       = true
  apply_immediately       = true

  tags = {
    Name = "Managed PostgreSQL"
  }
}

resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "secrets-manager-policy"
  description = "Policy to allow access to Secrets Manager secrets"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_manager_policy_attachment" {
  role       = data.aws_iam_role.existing_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

resource "aws_iam_role_policy_attachment" "rds_iam_auth_role_attachment" {
  role       = data.aws_iam_role.existing_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

data "aws_iam_role" "existing_role" {
  name = "docker-external-app"
}
