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


resource "aws_security_group" "ec2_launch_template_sg" {
  name        = "ec2_launch_template_sg"
  description = "Allow inbound traffic"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [format("%s/32", trimspace(data.http.my_ip.response_body))]
  }

    # broad for now
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

resource "aws_iam_instance_profile" "ec2_role" {
  name = "ec2-instance-role-profile"
  role = data.aws_iam_role.existing_role.name
}

resource "aws_launch_template" "ec2_launch_template" {
  image_id      = data.aws_ssm_parameter.ami.value
#   instance_type = var.instance_type
  instance_type = "t2.nano"

  key_name = data.aws_key_pair.key_pair.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_launch_template_sg.id]
  }
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_role.name
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

# resource "aws_autoscaling_attachment" "asg_attachment" {
#   autoscaling_group_name = aws_autoscaling_group.ec2_autoscaling_group_name.name
#   alb_target_group_arn   = aws_lb_target_group.ec2_lb_target_group.arn  
# }
