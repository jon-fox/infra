provider "aws" {
  region = var.region
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/account/vpc_id"  
}

# Security group for VPC Endpoint to allow Lambda outbound access to SSM over HTTPS
resource "aws_security_group" "ssm_vpc_endpoint_sg" {
  name        = "lambda_ssm_vpc_sg"
  description = "Allow Lambda to access SSM via VPC endpoint"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_subnets" "selected_subnets" {
  filter {
    name   = "tag:Name"
    values = ["PublicSubnet01", "PublicSubnet02"] 
  }
}


resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = data.aws_ssm_parameter.vpc_id.value
  service_name      = "com.amazonaws.${var.region}.ssm"
  subnet_ids        = data.aws_subnets.selected_subnets.ids
  security_group_ids = [aws_security_group.ssm_vpc_endpoint_sg.id]
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
}

# Uncomment the following code block to create VPC endpoints for SSM Messages and EC2 Messages
# resource "aws_vpc_endpoint" "ssm_messages" {
#   vpc_id            = data.aws_ssm_parameter.vpc_id.value
#   service_name      = "com.amazonaws.${var.region}.ssmmessages"
#   subnet_ids        = aws_subnet.all_subnets[*].id  # Include all subnets
#   security_group_ids = [aws_security_group.ssm_vpc_endpoint_sg.id]
#   vpc_endpoint_type = "Interface"
# }

# resource "aws_vpc_endpoint" "ec2_messages" {
#   vpc_id            = data.aws_ssm_parameter.vpc_id.value
#   service_name      = "com.amazonaws.${var.region}.ec2messages"
#   subnet_ids        = aws_subnet.all_subnets[*].id  # Include all subnets
#   security_group_ids = [aws_security_group.ssm_vpc_endpoint_sg.id]
#   vpc_endpoint_type = "Interface"
# }

