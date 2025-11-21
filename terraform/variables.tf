variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID where EC2 will be launched"
}

variable "subnet_id" {
  description = "Subnet ID for EC2"
}

variable "key_name" {
  description = "AWS Key Pair name"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "instance_name" {
  default = "redis-server"
}

variable "redis_port" {
  default = 6379
}

variable "owner" {
  default = "Abhinav"
}

variable "env" {
  default = "dev"
}

