variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  # default     = "g4dn.xlarge"
  # default     = "g4dn.xlarge" #nvidia based gpu
  default = "t3.xlarge"
}

variable "ami_id" {
  description = "AMI ID to use for the EC2 instances"
  default     = "ami-0123456789abcdef0"  # Replace with your specific AMI ID
}
