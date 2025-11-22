variable "aws_region" {
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_master_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "private_subnet_replica_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair"
}

variable "allowed_ssh_cidr" {
  type    = string
  default = "0.0.0.0/0" 
}

variable "redis_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "redis_port" {
  type    = number
  default = 6379
}

variable "owner" {
  type    = string
  default = "Abhinav"
}

variable "env" {
  type    = string
  default = "dev"
}
