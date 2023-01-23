variable "environment" {
  type        = string
  default     = "production"
  description = "Development environment. Eg: staging, production, etc."
}

variable "vpc_id" {
  type        = string
  description = "Id for VPC where Gitlab instance is located."
}

variable "ami_id" {
  type        = string
  default     = "ami-00c7d9a63c83ba329"
  description = "Gitlab published AMI id. Default is GitLab CE 14.9.3 ap-south-1 region AMI."
}

variable "instance_type" {
  type        = string
  default     = "c5.xlarge"
  description = "Gitlab EC2 instance type. Default is c5.xlarge."
}

variable "private_subnet_id" {
  type        = string
  description = "Id of a private subnet for the VPC where Gitlab instance is located."
}

variable "volume_type" {
  type        = string
  default     = "gp3"
  description = "Root EBS volume type for Gitlab instance."
}

variable "volume_size" {
  type        = number
  default     = 100
  description = "Size of root EBS volume for Gitlab instance."
}

variable "volume_iops" {
  type        = number
  default     = 3000
  description = "IOPS for the Gitlab EBS volume"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet Ids for Gitlab load balancer."
}

variable "create_gitlab_route53_record" {
  type        = bool
  default     = true
  description = "Whether to create a domain in Route53 for your Gitlab."
}
variable "gitlab_fqdn" {
  type        = string
  description = "Fully qualified domain name for the hosted Gitlab instance. Eg: gitlab.example.com"
}

variable "gitlab_domain" {
  type        = string
  description = "Domain name for the hosted Gitlab instance. Eg: gitlab in gitlab.example.com"
}

variable "hosted_zone" {
  type        = string
  description = "Route53 hosted zone where gitlab domain will be created. Eg: example.com"
}

variable "create_acm_certificate" {
  type        = bool
  default     = true
  description = "Whether to create SSL certificate for the Gitlab domain. If false, yo need to provide a valid AMC certificate arn in acm_certificate_arn variable."
}

variable "acm_certificate_arn" {
  type        = string
  default     = null
  description = "ARN for ACM certificate to use for Gitlab domain."
}

variable "healthcheck_healthy_threshold" {
  type        = number
  description = "Number of consecutive health checks successes required before considering an unhealthy target healthy."
  default     = 3
}

variable "healthcheck_unhealthy_threshold" {
  type        = number
  description = "Number of consecutive health check failures required before considering the target unhealthy."
  default     = 3
}

variable "healthcheck_interval" {
  type        = number
  description = "Approximate amount of time, in seconds, between health checks of an individual target."
  default     = 30
}

variable "healthcheck_matcher" {
  type        = string
  default     = "200"
  description = "Response codes to use when checking for a healthy responses from a target."
}

variable "healthcheck_path" {
  type        = string
  default     = "/-/readiness"
  description = "Destination for the health check request."
}

variable "healthcheck_port" {
  type        = string
  description = "Port to use to connect with the target."
  default     = "80"
}

variable "healthcheck_protocol" {
  type        = string
  description = "Protocol to use to connect with the target."
  default     = "HTTP"
}

variable "healthcheck_timeout" {
  type        = number
  description = "Amount of time, in seconds, during which no response means a failed health check."
  default     = 5
}

variable "gitlab_ssh_public_key" {
  type        = string
  description = "Public key to the key pair to access Gitlab over SSH"
  default     = null
}

variable "gitlab_pg_create_db_parameter_group" {
  type        = bool
  description = "Create parameter group for Gitlab RDS"
  default     = false
}

variable "gitlab_pg_parameter_group_name" {
  type        = string
  description = "Parameter Group name for Gitlab RDS Postgres"
  default     = null
}

variable "gitlab_pg_parameters" {
  type        = list(map(string))
  description = "Parameter list for Gitlab RDS"
  default     = []
}

variable "gitlab_pg_subnet_ids" {
  type        = list(string)
  description = "List of subnet-ids for Gitlab RDS"
}

variable "gitlab_pg_allocated_storage" {
  type        = number
  default     = 100
  description = "Gitlab RDS Postgres allocated storage"
}

variable "gitlab_pg_storage_type" {
  type        = string
  default     = "gp3"
  description = "Storage type for Gitlab  RDS Postgres"
}

variable "gitlab_pg_db_name" {
  type        = string
  default     = "gitlabhq-production"
  description = "Postgres DB name for Gitlab"
}

variable "gitlab_pg_port" {
  type        = number
  description = "The port on which the DB accepts connections"
  default     = 5432
}

variable "gitlab_pg_engine_version" {
  type        = string
  default     = "12.11"
  description = "Postgres engine version"
}

variable "gitlab_pg_db_instance_class" {
  type        = string
  default     = "db.m5.large"
  description = "Postgres RDS instance class"
}

variable "gitlab_pg_username" {
  type        = string
  description = "Username for Gitlab Postgres DB"
}

variable "gitlab_pg_password" {
  type        = string
  description = "Password for Gitlab Postgres DB"
  sensitive   = true
}

variable "gitlab_pg_publicly_accessible" {
  type        = bool
  default     = false
  description = "Allow Gitlab RDS publicly accessible"
}

variable "gitlab_redis_node_type" {
  type        = string
  default     = "cache.t3.medium"
  description = "Instance class for Gitlab Redis"
}

variable "gitlab_redis_num_cache_nodes" {
  type        = number
  description = "Number of cache node in Gitlab Redis"
  default     = 1
}

variable "gitlab_redis_create_parameter_group" {
  type        = bool
  description = "Create parameter group for Gitlab Redis"
  default     = false
}

variable "gitlab_redis_parameter_group_name" {
  type        = string
  description = "Parameter group name for Gitlab Redis"
  default     = null
}

variable "gitlab_redis_engine_version" {
  type        = string
  default     = "7.0"
  description = "Redis engine version for Gitlab Redis"
}

variable "gitlab_redis_port" {
  type        = number
  description = "Redis port for Gitlab Redis"
  default     = 6379
}

variable "gitlab_redis_create_subnet_group" {
  type        = bool
  description = "Create subnet group for Gitlab Redis"
  default     = true
}

variable "gitlab_redis_subnet_group_name" {
  type        = string
  description = "Subnet group name for Gitlab Redis"
  default     = null
}

variable "gitlab_redis_subnet_ids" {
  type        = list(string)
  description = "List of subnet-ids for Gitlab Redis"
  default     = []
}

variable "gitlab_redis_parameter_group" {
  type = object({
    name   = string
    family = string
  })
  description = "Gitlab Redis Parameter group config"
  default = {
    name   = null
    family = null
  }
}

variable "enable_gitlab_backup_to_s3" {
  type        = bool
  default     = false
  description = "Enable Gitlab backup on S3 bucket"
}

variable "gitlab_backup_bucket_name" {
  type        = string
  default     = null
  description = "Name of S3 bucket to be used for Gitlab backup"
}

variable "private_key" {
  type        = string
  description = "Private key to execute ansible playbook on Gitlab instance."
}

variable "create_ses_identity" {
  type        = bool
  description = "Create a Amazon SES domain identity for Gitlab SMTP service. The domain should be hosted on Route53."
  default     = false
}

variable "ses_domain" {
  type        = string
  description = "Route53 hosted domain name for Amazon SES. If no value provided, value of Gitlab hosted zone will be assumed as default."
  default     = null
}

variable "aws_region" {
  type        = string
  description = "AWS region code. Eg: ap-south-1"
  default     = "ap-south-1"
}

variable "ses_username" {
  type        = string
  description = "Username for Gitlab SMTP user"
  default     = "gitlab-smtp-user"
}

variable "additional_tags" {
  type        = map(string)
  default     = {}
  description = "A map of additional tags to attach to the resources."
}
