output "gitlab_pg_address" {
  value       = module.gitlab.gitlab_pg_address
  description = "Gitlab Postgres address"
}

output "gitlab_redis_address" {
  value       = module.gitlab.gitlab_redis_address
  description = "Gitlab Redis address"
}

output "gitlab_url" {
  value       = module.gitlab.gitlab_complete_url
  description = "Gitlab url including the url schema"
}
