module "gitlab" {
  source = "../../"

  gitlab_domain                       = "gitlab"
  gitlab_fqdn                         = "gitlab.example.com"
  hosted_zone                         = "example.com"
  private_subnet_id                   = "subnet-u8dy389d78qhh338"
  public_subnet_ids                   = ["subnet-h89dj8d3j2jd8", "subnet-jd8jq3dj89qj9jd3", "subnet-jd89jh89dj9dj9j9qw"]
  vpc_id                              = "vpc-89rh423789hr982h98"
  gitlab_ssh_public_key               = "ssh publickey"
  gitlab_pg_password                  = "foobarbaz"
  gitlab_pg_publicly_accessible       = false
  gitlab_pg_subnet_ids                = ["subnet-u8dy389d78qhh338", "subnet-hde38hd89qhdwhw"]
  gitlab_pg_username                  = "gitlab"
  gitlab_redis_create_parameter_group = true
  gitlab_redis_parameter_group = {
    name   = "gitlab-redis"
    family = "redis7"
  }
  gitlab_redis_subnet_ids    = ["subnet-u8dy389d78qhh338", "subnet-hde38hd89qhdwhw"]
  enable_gitlab_backup_to_s3 = true
  gitlab_backup_bucket_name  = "example-gitlab-backup"
  private_key                = var.private_key
  create_ses_identity        = true
}
