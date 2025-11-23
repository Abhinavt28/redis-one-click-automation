terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket  = "abhinav-redis-tf-state"
    key     = "redis-infra/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
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

############################
# VPC
############################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name  = "redis-vpc"
    OWNER = var.owner
    ENV   = var.env
  }
}

############################
# INTERNET GATEWAY
############################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "redis-igw"
  }
}

############################
# SUBNETS
############################

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public-bastion-subnet"
  }
}

resource "aws_subnet" "private_master" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_master_cidr
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"

  tags = {
    Name = "private-master-subnet"
  }
}

resource "aws_subnet" "private_replica" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_replica_cidr
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"

  tags = {
    Name = "private-replica-subnet"
  }
}

############################
# NAT GATEWAY
############################

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "redis-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "redis-nat"
  }
}

############################
# ROUTE TABLES
############################

resource "aws_route_table" "public_rt" {
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
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_route_table" "private_rt" {
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
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_master.id
}

resource "aws_route_table_association" "private_replica_assoc" {
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_replica.id
}

############################
# SECURITY GROUPS
############################

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH from your laptop"
  vpc_id      = aws_vpc.main.id

  ingress {
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
}

resource "aws_security_group" "redis_sg" {
  name        = "redis-db-sg"
  description = "Allow Redis + SSH from Bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description = "Redis internal"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################
# AMI
############################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

############################
# BASTION
############################

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name = "bastion-host"
  }
}

############################
# USERDATA PUBLIC KEY
############################

locals {
  jenkins_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCwT/Edy+Cs8HCXIP104/uRUBveNE8srLNoqVI+Ay46OULDttqQAwS6s/DWIRzyCGCr60NGiCzhPaeE7bFRBP9CceZgSsorvgkGb68WFY/C2GoGnxkOLoGGm1weLmrublDNXyKOsh/GUWukvvVmDDyQYX7UaiuJTLLGZSbq+Ej1lydbP+dVsUEZQENsoTkRjAwEPtCVypcz2LAJ/3VwL88IBwYfLzwDvqtI1WDzcHjQ39fKXFB+f82jwV6V7ns3HjoJPJLcbLZvyr0l+ESZRx8cfrGXqOF2Cd45aBvAmPyrXCSj9IsPtuB1PoEpGtI0FDnJl8VaZ714V8vc1+ZbLcAMziT4IJXPWl7pRYNChkmw8Bp7TSfvzyLZEnoez1Cn/OkBrzQ+9poyKFBOJHYHB+xxPpSRaMwGCDjqYw//K2eg/FDt+GOJNwoqfix0fFsijz7tFNIgdRp5nf3IVBx3H8KNsSMgN8o2JMInI/PczDTpSN4mBVGS1yisD18GGAPKWea+m99iUk0GnTI+nyk9kTYPo50J8NmYyglPXbLSpJmKQaEHael7M7Sz5nNDhrztgYEbWkWBCRzmSQiGnfEboqeJmfiNCDQOSwX4gnTuAuJ3auKH9l2Pjy0YJa9UoSw1nfbndPtoShyjUdl39LoIZiLCFNdmnqGM0MExeMoaMeO+w== ubuntu@ip-10-0-1-53"
}

############################
# REDIS MASTER
############################

resource "aws_instance" "redis_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.redis_instance_type
  subnet_id              = aws_subnet.private_master.id
  vpc_security_group_ids = [aws_security_group.redis_sg.id]
  key_name               = var.key_name

  tags = {
    Name = "redis-master"
    Role = "master"
  }

  user_data = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y redis-server

sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf

mkdir -p /home/ubuntu/.ssh
echo "${local.jenkins_public_key}" > /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

systemctl enable redis-server
systemctl restart redis-server
EOF
}

############################
# REDIS REPLICA
############################

resource "aws_instance" "redis_replica" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.redis_instance_type
  subnet_id              = aws_subnet.private_replica.id
  vpc_security_group_ids = [aws_security_group.redis_sg.id]
  key_name               = var.key_name

  tags = {
    Name = "redis-replica"
    Role = "replica"
  }

  user_data = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y redis-server

sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf
echo "replicaof ${aws_instance.redis_master.private_ip} 6379" >> /etc/redis/redis.conf

mkdir -p /home/ubuntu/.ssh
echo "${local.jenkins_public_key}" > /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

systemctl enable redis-server
systemctl restart redis-server
EOF
}
