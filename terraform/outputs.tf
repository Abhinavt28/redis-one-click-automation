output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = aws_instance.bastion.public_ip
}

output "redis_master_private_ip" {
  description = "Private IP of Redis master"
  value       = aws_instance.redis_master.private_ip
}

output "redis_replica_private_ip" {
  description = "Private IP of Redis replica"
  value       = aws_instance.redis_replica.private_ip
}

output "redis_master_instance_id" {
  description = "Instance ID of Redis master"
  value       = aws_instance.redis_master.id
}

output "redis_replica_instance_id" {
  description = "Instance ID of Redis replica"
  value       = aws_instance.redis_replica.id
}
