variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_master_cidr" {
  description = "CIDR for Redis master subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_replica_cidr" {
  description = "CIDR for Redis replica subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "key_name" {
  description = "Existing AWS key pair name"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR from which SSH to bastion is allowed"
  type        = string
  default     = "0.0.0.0/0" # CHANGE THIS to your IP for security
}

variable "redis_instance_type" {
  description = "Instance type for Redis EC2"
  type        = string
  default     = "t3.micro"
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "owner" {
  description = "Owner tag"
  type        = string
  default     = "Abhinav"
}

variable "env" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}
