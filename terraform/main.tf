terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "abhinav-redis-tf-state"
    key            = "redis-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "redis-tf-lock"
    encrypt        = true
  }

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
# Networking - VPC & Subnets
# -----------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name  = "redis-vpc"
    OWNER = var.owner
    ENV   = var.env
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "redis-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-bastion-subnet"
  }
}

resource "aws_subnet" "private_master" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_master_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-master-subnet"
  }
}

resource "aws_subnet" "private_replica" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_replica_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-replica-subnet"
  }
}

# -----------------------------
# NAT Gateway & Route Tables
# -----------------------------

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "redis-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "redis-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private_master_assoc" {
  subnet_id      = aws_subnet.private_master.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_replica_assoc" {
  subnet_id      = aws_subnet.private_replica.id
  route_table_id = aws_route_table.private.id
}

# -----------------------------
# Security Groups
# -----------------------------

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH from my IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_security_group" "redis_sg" {
  name        = "db-sg"
  description = "Redis master & replica security group"
  vpc_id      = aws_vpc.main.id

  # SSH only from Bastion
  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Redis traffic only inside VPC
  ingress {
    description = "Redis from within VPC"
    from_port   = var.redis_port
    to_port     = var.redis_port
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
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

# -----------------------------
# Bastion Host (Public Subnet)
# -----------------------------
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name  = "bastion-host"
    Role  = "bastion"
    OWNER = var.owner
    ENV   = var.env
  }
}

# -----------------------------
# Redis Master
# -----------------------------
resource "aws_instance" "redis_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.redis_instance_type
  subnet_id              = aws_subnet.private_master.id
  vpc_security_group_ids = [aws_security_group.redis_sg.id]
  key_name               = var.key_name

  tags = {
    Name  = "redis-master"
    Role  = "redis-master"
    OWNER = var.owner
    ENV   = var.env
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y redis-server
              sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf
              sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf
              systemctl enable redis-server
              systemctl restart redis-server
              EOF
}

# -----------------------------
# Redis Replica
# -----------------------------
resource "aws_instance" "redis_replica" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.redis_instance_type
  subnet_id              = aws_subnet.private_replica.id
  vpc_security_group_ids = [aws_security_group.redis_sg.id]
  key_name               = var.key_name

  tags = {
    Name  = "redis-replica"
    Role  = "redis-replica"
    OWNER = var.owner
    ENV   = var.env
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y redis-server
              sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf
              sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf
              echo "replicaof ${aws_instance.redis_master.private_ip} ${var.redis_port}" >> /etc/redis/redis.conf
              systemctl enable redis-server
              systemctl restart redis-server
              EOF
}
