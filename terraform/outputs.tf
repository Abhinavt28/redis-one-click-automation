output "vpc_id" {
  value = aws_vpc.main.id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "redis_master_private_ip" {
  value = aws_instance.redis_master.private_ip
}

output "redis_replica_private_ip" {
  value = aws_instance.redis_replica.private_ip
}
