output "redis_public_ip" {
  value = aws_instance.redis.public_ip
}

output "redis_private_ip" {
  value = aws_instance.redis.private_ip
}

output "redis_instance_id" {
  value = aws_instance.redis.id
}

