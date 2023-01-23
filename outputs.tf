output "gitlab_instance_id" {
  description = "Instance Id of the Gitlab EC2 instance."
  value       = aws_instance.gitlab.id
}

output "gitlab_sg_id" {
  description = "Id of Gitlab instance security group."
  value       = aws_security_group.gitlab.id
}

output "gitlab_lb_sg_id" {
  description = "Id of Gitlab load balancer security group."
  value       = aws_security_group.gitlab_lb.id
}

output "gitlab_lb_arn" {
  description = "The ARN for Gitlab load balancer."
  value       = module.elb.this_elb_arn
}

output "acm_certificate_arn" {
  description = "The ARN of the certificate."
  value       = module.acm.acm_certificate_arn
}

output "acm_certificate_status" {
  description = "Status of the certificate."
  value       = module.acm.acm_certificate_status
}

output "gitlab_pg_address" {
  value       = module.gitlab_pg.db_instance_address
  description = "Gitlab RDS DB instance address"
}

output "gitlab_redis_address" {
  value       = aws_elasticache_cluster.gitlab_redis.cache_nodes[0].address
  description = "Gitlab Redis cluster address"
}

output "gitlab_complete_url" {
  value = local.gitlab_complete_url
}
