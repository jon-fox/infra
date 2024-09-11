provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    key    = "terraform/vpc_endpoint/terraform.tfstate"  # Path inside the bucket to store the state
    region = "us-east-1"  # AWS region, e.g., us-west-2
  }
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

  ingress {
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

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = data.aws_ssm_parameter.vpc_id.value
  service_name      = "com.amazonaws.${var.region}.secretsmanager"
  subnet_ids        = data.aws_subnets.selected_subnets.ids
  security_group_ids = [aws_security_group.ssm_vpc_endpoint_sg.id]
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id       = data.aws_ssm_parameter.vpc_id.value
  service_name = "com.amazonaws.us-east-1.s3"  # Adjust based on your AWS region

  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.public.id]  # Ensure your route table is associated with the subnets that need S3 access
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_ssm_parameter.vpc_id.value
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = data.aws_subnets.selected_subnets.ids[0]
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_association_2" {
  subnet_id      = data.aws_subnets.selected_subnets.ids[1]
  route_table_id = aws_route_table.public.id
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

