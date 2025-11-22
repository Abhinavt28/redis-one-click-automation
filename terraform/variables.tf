variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_master_cidr" {
  default = "10.0.2.0/24"
}

variable "private_subnet_replica_cidr" {
  default = "10.0.3.0/24"
}

variable "key_name" {}

variable "allowed_ssh_cidr" {
  default = "0.0.0.0/0"
}

variable "redis_instance_type" {
  default = "t3.micro"
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
