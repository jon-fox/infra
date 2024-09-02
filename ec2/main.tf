provider "aws" {
  region = var.region
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/account/vpc_id"  
}

data "http" "my_ip" {
  url = "http://checkip.amazonaws.com/"
}

data "aws_ssm_parameter" "ami" {
  name = "/account/ec2/ami"  
}

data "aws_ssm_parameter" "ec2_name" {
  name = "/account/ec2_name"  
}

data "aws_ssm_parameter" "key_pair_name" {
  name = "/account/ec2/key_pair_name"  
}

data "aws_ssm_parameter" "s3_bucket_name" {
  name = "/account/config_bucket_name"  
}

data "aws_ssm_parameter" "acm_certificate_arn" {
  name = "/account/api/acm_cert"  
}

data "aws_subnets" "selected_vpc_subnets" {

  filter {
    name   = "vpc-id"
    values = [data.aws_ssm_parameter.vpc_id.value]
  }

  filter {
    name   = "availabilityZone"
    values = ["us-east-1a", "us-east-1b"]
  }

    filter {
    name   = "tag:Name"
    values = ["*Public*"]
  }
}

data "aws_key_pair" "key_pair" {
  key_name = data.aws_ssm_parameter.key_pair_name.value
}


resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow inbound traffic"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_launch_template_sg" {
  name        = "ec2_launch_template_sg"
  description = "Allow inbound traffic from alb"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_role" "existing_role" {
  name = "docker-external-app"
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role = data.aws_iam_role.existing_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_role" {
  name = "ec2-instance-role-profile"
  role = data.aws_iam_role.existing_role.name
}

# data "aws_ami" "latest_amazon_linux_2023" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["al2023-ami-2023.5.20240819.0-kernel-6.1-x86_64"]
#   }
# }

resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.selected_vpc_subnets.ids

  enable_deletion_protection = false

  tags = {
    Name = "app-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value

  health_check {
    path                = "/"
    port                = 8080
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "app-tg"
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_ssm_parameter.acm_certificate_arn.value

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}


resource "aws_launch_template" "ec2_launch_template" {
  image_id      = data.aws_ssm_parameter.ami.value
  # image_id      = var.ami_id
  instance_type = var.instance_type
  # instance_type = "t2.nano"

  key_name = data.aws_key_pair.key_pair.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_launch_template_sg.id]
  }
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_role.name
  }

  user_data = base64encode(data.template_file.init.rendered)

    block_device_mappings {
    device_name = "/dev/xvda"  # Root volume
    ebs {
      volume_size           = 40  # Root volume size in GB
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }
}

data "template_file" "init" {
  template = "${file("${path.module}/user_data.sh")}"
  vars = {
    # region         = var.region,
    # repository_url = data.aws_ecr_repository.ecr_repo.repository_url,
    bucket_name    = data.aws_ssm_parameter.s3_bucket_name.value,
    script_path    = "user_data"
  }
}

resource "aws_autoscaling_group" "ec2_autoscaling_group_name" {
  launch_template {
    id      = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }

  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  vpc_zone_identifier =  data.aws_subnets.selected_vpc_subnets.ids

  tag {
    key                 = "Name"
    value               = data.aws_ssm_parameter.ec2_name.value
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ecr_repository" "ecr_repo" {
  name = "app-ecr-repo"
}

resource "aws_iam_role_policy" "ecr_policy" {
  name   = "ecr-policy"
  role   = data.aws_iam_role.existing_role.name
  policy = data.aws_iam_policy_document.ecr_policy.json
}

data "aws_iam_policy_document" "ecr_policy" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]

    resources = [
      data.aws_ecr_repository.ecr_repo.arn
    ]
  }
}

# resource "aws_autoscaling_attachment" "asg_attachment" {
#   autoscaling_group_name = aws_autoscaling_group.ec2_autoscaling_group_name.name
#   alb_target_group_arn   = aws_lb_target_group.ec2_lb_target_group.arn  
# }
