/* Resources for Gitlab Redis setup */
resource "aws_security_group" "gitlab_redis" {
  name        = "${local.environment_prefix}-gitlab-redis"
  vpc_id      = data.aws_vpc.vpc.id
  description = "Security group for Gitlab Redis"
  ingress = [
    {
      from_port        = var.gitlab_redis_port
      protocol         = "tcp"
      to_port          = var.gitlab_redis_port
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [aws_security_group.gitlab.id]
      self             = false
      description      = "allow TCP access from Gitlab instance"
    }
  ]
  tags = merge({
    Name = "${local.environment_prefix}-gitlab-redis"
  }, local.default_tags, var.additional_tags)
}

resource "aws_elasticache_parameter_group" "gitlab_redis" {
  count  = var.gitlab_redis_create_parameter_group == true ? 1 : 0
  family = var.gitlab_redis_parameter_group.family
  name   = var.gitlab_redis_parameter_group.name
  tags = merge({
    Name = "${local.environment_prefix}-${var.gitlab_redis_parameter_group.name}"
  }, local.default_tags, var.additional_tags)
  lifecycle {
    precondition {
      condition     = var.gitlab_redis_parameter_group.name != null && var.gitlab_redis_parameter_group.family != null
      error_message = "Provide name and family in gitlab_redis_parameter_group for Parameter Group creation"
    }
  }
}

resource "aws_elasticache_subnet_group" "gitlab_redis" {
  count      = var.gitlab_redis_create_subnet_group == true ? 1 : 0
  name       = "${local.environment_prefix}-gitlab-redis"
  subnet_ids = var.gitlab_redis_subnet_ids

  tags = merge({
    Name = "${local.environment_prefix}-gitlab-redis"
  }, local.default_tags, var.additional_tags)

  lifecycle {
    precondition {
      condition     = var.gitlab_redis_create_subnet_group && length(var.gitlab_redis_subnet_ids) != 0
      error_message = "Subnet Group creation needs subnet-ids. Add subnet-ids to gitlab_redis_subnet_ids"
    }
  }
}

resource "aws_elasticache_cluster" "gitlab_redis" {
  cluster_id           = "${local.environment_prefix}-gitlab-redis"
  engine               = "redis"
  node_type            = var.gitlab_redis_node_type
  num_cache_nodes      = var.gitlab_redis_num_cache_nodes
  parameter_group_name = var.gitlab_redis_create_parameter_group == true ? aws_elasticache_parameter_group.gitlab_redis[0].name : var.gitlab_redis_parameter_group_name
  engine_version       = var.gitlab_redis_engine_version
  port                 = var.gitlab_redis_port
  security_group_ids   = [aws_security_group.gitlab_redis.id]
  subnet_group_name    = var.gitlab_redis_create_subnet_group == true ? aws_elasticache_subnet_group.gitlab_redis[0].name : var.gitlab_redis_subnet_group_name

  tags = merge({
    Name = "${local.environment_prefix}-gitlab-redis"
  }, local.default_tags, var.additional_tags)

  lifecycle {
    precondition {
      condition = anytrue([
        (var.gitlab_redis_create_parameter_group == false && var.gitlab_redis_parameter_group_name != null),
        (var.gitlab_redis_create_parameter_group)
      ])
      error_message = "Parameter Group creation for Gitlab Redis is set to ${var.gitlab_redis_create_parameter_group}. Provide a pre-existing Parameter Group name."
    }
  }
}
