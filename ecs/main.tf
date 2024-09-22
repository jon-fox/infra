############################# ECS ##############################
#leaving here, may use later
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "app-cluster"
}

resource "aws_ecs_capacity_provider" "gpu_capacity_provider" {
  name = "gpu-ecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ec2_autoscaling_group_name.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100 # target of cpu usage before scaling
      minimum_scaling_step_size = 1 # number of instances to scale up by
      maximum_scaling_step_size = 1 # max number of instances to scale up by
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_capacity" {
  cluster_name          = aws_ecs_cluster.ecs_cluster.name
  capacity_providers    = [aws_ecs_capacity_provider.gpu_capacity_provider.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.gpu_capacity_provider.name
    weight            = 1
  }
}

resource "aws_ecs_task_definition" "gpu_task" {
  family                   = "gpu-task"
  execution_role_arn        = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn             = aws_iam_role.ecs_task_role.arn
  network_mode              = "bridge"
  requires_compatibilities  = ["EC2"]

  container_definitions = file("task-definition.json")
  
}

resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-app-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.gpu_task.arn

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.gpu_capacity_provider.name
    weight            = 1
  }

  # network_configuration {
  #   subnets         = data.aws_subnets.selected_vpc_subnets.ids
  #   security_groups = [aws_security_group.ec2_launch_template_sg.id]  # Reuse the SG here
  # }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



############################# ECS ROLE ##############################

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_task_policy" {
  name   = "ecsTaskPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::my-bucket/*"
      },
      {
        Effect = "Allow",
        Action = [
          "rds:DescribeDBInstances",
          "rds:Connect"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

################## ECS Execution Role ##################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy" "existing_ecr_policy" {
  name = "ECRAccessPolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = data.aws_iam_policy.existing_ecr_policy.arn
}
