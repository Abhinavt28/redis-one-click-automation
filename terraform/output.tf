output "bastion_public_ip" {
  description = "Public IP of Bastion Host"
  value       = aws_instance.bastion.public_ip
}

output "redis_master_private_ip" {
  description = "Private IP of Redis Master"
  value       = aws_instance.redis_master.private_ip
}

output "redis_replica_private_ip" {
  description = "Private IP of Redis Replica"
  value       = aws_instance.redis_replica.private_ip
}
