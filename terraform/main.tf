terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------
# Security Group for Redis
# -----------------------------
resource "aws_security_group" "redis_sg" {
  name        = "redis-sg"
  description = "Security group for Redis EC2"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow Redis from anywhere (change for production)"
    from_port   = var.redis_port
    to_port     = var.redis_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow All Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "redis-sg"
    Role = "redis-server"
  }
}

# -----------------------------
# EC2 Instance for Redis
# -----------------------------
resource "aws_instance" "redis" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  associate_public_ip_address = true
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.redis_sg.id]

  tags = {
    Name = var.instance_name
    Role = "redis-server"
    OWNER = var.owner
    ENV   = var.env
  }
}

# -----------------------------
# Get Latest Ubuntu AMI
# -----------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

