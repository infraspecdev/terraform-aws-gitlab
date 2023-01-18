locals {
  managed_by = "Terraform"
}

resource "aws_instance" "gitlab" {
  count                       = 1
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.gitlab.id]
  key_name                    = var.gitlab_ssh_public_key != null ? aws_key_pair.gitlab_ssh[0].key_name : null
  iam_instance_profile        = aws_iam_instance_profile.gitlab.name
  root_block_device {
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    delete_on_termination = false
  }
  tags = {
    Name        = "${var.environment_prefix}-gitlab"
    Environment = var.environment_prefix
    ManagedBy   = local.managed_by
  }
}

resource "aws_key_pair" "gitlab_ssh" {
  count      = var.gitlab_ssh_public_key != null ? 1 : 0
  key_name   = "${var.environment_prefix}-gitlab-key-pair"
  public_key = var.gitlab_ssh_public_key
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_route53_zone" "zone" {
  name = var.hosted_zone
}

resource "aws_security_group" "gitlab" {
  name        = "${var.environment_prefix}-gitlab"
  vpc_id      = data.aws_vpc.vpc.id
  description = "Security group for Gitlab instance"
  ingress = [
    {
      from_port        = 80
      protocol         = "tcp"
      to_port          = 80
      cidr_blocks      = [data.aws_vpc.vpc.cidr_block]
      ipv6_cidr_blocks = data.aws_vpc.vpc.ipv6_cidr_block != "" ? tolist([data.aws_vpc.vpc.ipv6_cidr_block]) : []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
      description      = "allow http ingress from within VPC"
    },
    {
      from_port        = 443
      protocol         = "tcp"
      to_port          = 443
      cidr_blocks      = [data.aws_vpc.vpc.cidr_block]
      ipv6_cidr_blocks = data.aws_vpc.vpc.ipv6_cidr_block != "" ? tolist([data.aws_vpc.vpc.ipv6_cidr_block]) : []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
      description      = "allow https ingress from within VPC"
    },
    {
      from_port        = 22
      protocol         = "tcp"
      to_port          = 22
      cidr_blocks      = [data.aws_vpc.vpc.cidr_block]
      ipv6_cidr_blocks = data.aws_vpc.vpc.ipv6_cidr_block != "" ? tolist([data.aws_vpc.vpc.ipv6_cidr_block]) : []
      prefix_list_ids  = []
      security_groups  = [aws_security_group.gitlab_lb.id]
      self             = false
      description      = "allow SSH within VPC"
    }
  ]
  egress = [
    {
      from_port        = 0
      protocol         = "-1"
      to_port          = 0
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
      description      = "allow all egress"
    }
  ]
  tags = {
    Environment = var.environment_prefix
    ManagedBy   = local.managed_by
  }
}

resource "aws_security_group" "gitlab_lb" {
  name        = "${var.environment_prefix}-gitlab-lb"
  vpc_id      = data.aws_vpc.vpc.id
  description = "Security group for Gitlab load balancer"
  ingress = [
    {
      from_port        = 80
      protocol         = "tcp"
      to_port          = 80
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
      description      = "allow http ingress from anywhere"
    },
    {
      from_port        = 443
      protocol         = "tcp"
      to_port          = 443
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
      description      = "allow https ingress from anywhere"
    },
    {
      from_port        = 22
      protocol         = "tcp"
      to_port          = 22
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
      description      = "allow SSH ingress from anywhere"
    }
  ]
  egress = [
    {
      from_port        = 0
      protocol         = "-1"
      to_port          = 0
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
      description      = "allow all egress"
    }
  ]
  tags = {
    Environment = var.environment_prefix
    ManagedBy   = local.managed_by
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = var.hosted_zone
  create    = var.create_gitlab_domain
  records = [
    {
      name = var.gitlab_domain
      type = "A"
      alias = {
        name    = module.elb.this_elb_dns_name
        zone_id = module.elb.this_elb_zone_id
      }
    },
  ]
}

module "acm" {
  source             = "terraform-aws-modules/acm/aws"
  version            = "~> 4.0"
  create_certificate = var.create_gitlab_domain
  domain_name        = var.gitlab_fqdn
  zone_id            = data.aws_route53_zone.zone.zone_id

  wait_for_validation = true

  tags = {
    Name = var.gitlab_domain
  }
}

module "elb" {
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 2.0"

  name = "${var.environment_prefix}-gitlab"

  subnets         = var.public_subnet_ids
  security_groups = [aws_security_group.gitlab_lb.id]
  internal        = false

  listener = [
    {
      instance_port     = 80
      instance_protocol = "HTTP"
      lb_port           = 80
      lb_protocol       = "HTTP"
    },
    {
      instance_port      = 80
      instance_protocol  = "HTTP"
      lb_port            = 443
      lb_protocol        = "HTTPS"
      ssl_certificate_id = var.create_acm_certificate ? module.acm.acm_certificate_arn : var.acm_certificate_arn
    },
    {
      instance_port     = 22
      instance_protocol = "TCP"
      lb_port           = 22
      lb_protocol       = "TCP"
    },
  ]

  health_check = {
    target              = "${var.healthcheck_protocol}:${var.healthcheck_port}${var.healthcheck_path}"
    interval            = var.healthcheck_interval
    healthy_threshold   = var.healthcheck_healthy_threshold
    unhealthy_threshold = var.healthcheck_unhealthy_threshold
    timeout             = var.healthcheck_timeout
  }
  #
  #  access_logs = {
  #    bucket = "my-access-logs-bucket"
  #  }

  // ELB attachments
  number_of_instances = length(aws_instance.gitlab)
  instances           = aws_instance.gitlab[*].id

  tags = {
    Environment = var.environment_prefix
  }
}

module "gitlab_pg" {
  source                    = "terraform-aws-modules/rds/aws"
  identifier                = "${var.environment_prefix}-gitlab-pg"
  create_db_instance        = true
  create_db_subnet_group    = true
  create_db_parameter_group = var.gitlab_pg_create_db_parameter_group
  parameter_group_name      = var.gitlab_pg_parameter_group_name
  parameters                = var.gitlab_pg_parameters
  db_subnet_group_name      = "${var.environment_prefix}-gitlab-pg"
  subnet_ids                = var.gitlab_pg_subnet_ids
  allocated_storage         = var.gitlab_pg_allocated_storage
  storage_type              = var.gitlab_pg_storage_type
  db_name                   = var.gitlab_pg_db_name
  port                      = tostring(var.gitlab_pg_port)
  engine                    = "postgres"
  engine_version            = var.gitlab_pg_engine_version
  instance_class            = var.gitlab_pg_db_instance_class
  username                  = var.gitlab_pg_username
  password                  = var.gitlab_pg_password
  create_random_password    = false
  publicly_accessible       = var.gitlab_pg_publicly_accessible
  vpc_security_group_ids    = [aws_security_group.gitlab_rds.id]
}

resource "aws_security_group" "gitlab_rds" {
  name        = "${var.environment_prefix}-gitlab-rds"
  vpc_id      = data.aws_vpc.vpc.id
  description = "Security group for Gitlab RDS"
  ingress = [
    {
      from_port        = var.gitlab_pg_port
      protocol         = "tcp"
      to_port          = var.gitlab_pg_port
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [aws_security_group.gitlab.id]
      self             = false
      description      = "allow TCP access from Gitlab instance"
    }
  ]
  tags = {
    Environment = var.environment_prefix
    ManagedBy   = local.managed_by
  }
}

resource "aws_elasticache_cluster" "gitlab_redis" {
  cluster_id           = "${var.environment_prefix}-gitlab-redis"
  engine               = "redis"
  node_type            = var.gitlab_redis_node_type
  num_cache_nodes      = var.gitlab_redis_num_cache_nodes
  parameter_group_name = var.gitlab_redis_create_parameter_group == true ? aws_elasticache_parameter_group.gitlab_redis[0].name : var.gitlab_redis_parameter_group_name
  engine_version       = var.gitlab_redis_engine_version
  port                 = var.gitlab_redis_port
  security_group_ids   = [aws_security_group.gitlab_redis.id]
  subnet_group_name    = var.gitlab_redis_create_subnet_group == true ? aws_elasticache_subnet_group.gitlab_redis[0].name : var.gitlab_redis_subnet_group_name

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

resource "aws_elasticache_parameter_group" "gitlab_redis" {
  count  = var.gitlab_redis_create_parameter_group == true ? 1 : 0
  family = var.gitlab_redis_parameter_group.family
  name   = var.gitlab_redis_parameter_group.name

  lifecycle {
    precondition {
      condition     = var.gitlab_redis_parameter_group.name != null && var.gitlab_redis_parameter_group.family != null
      error_message = "Provide name and family in gitlab_redis_parameter_group for Parameter Group creation"
    }
  }
}

resource "aws_elasticache_subnet_group" "gitlab_redis" {
  count      = var.gitlab_redis_create_subnet_group == true ? 1 : 0
  name       = "${var.environment_prefix}-gitlab-redis"
  subnet_ids = var.gitlab_redis_subnet_ids
  tags = {
    Name      = "${var.environment_prefix}-gitlab-redis"
    ManagedBy = local.managed_by
  }
  lifecycle {
    precondition {
      condition     = var.gitlab_redis_create_subnet_group && length(var.gitlab_redis_subnet_ids) != 0
      error_message = "Subnet Group creation needs subnet-ids. Add subnet-ids to gitlab_redis_subnet_ids"
    }
  }
}

resource "aws_security_group" "gitlab_redis" {
  name        = "${var.environment_prefix}-gitlab-redis"
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
  tags = {
    Environment = var.environment_prefix
    ManagedBy   = local.managed_by
  }
}

resource "aws_s3_bucket" "gitlab_backup" {
  count  = var.enable_gitlab_backup_to_s3 ? 1 : 0
  bucket = var.gitlab_backup_bucket_name
  lifecycle {
    precondition {
      condition = anytrue([
        (var.enable_gitlab_backup_to_s3 == false),
        (var.enable_gitlab_backup_to_s3 == true && var.gitlab_backup_bucket_name != null)
      ])
      error_message = "Gitlab backup to S3 is set to ${var.enable_gitlab_backup_to_s3}. gitlab_backup_bucket_name is mandatory to create S3 bucket."
    }

  }
}

resource "aws_s3_bucket_acl" "gitlab_backup" {
  count  = var.enable_gitlab_backup_to_s3 ? 1 : 0
  bucket = aws_s3_bucket.gitlab_backup[0].id
  acl    = "private"
}

data "aws_iam_policy_document" "gitlab_s3_backup" {
  count = var.enable_gitlab_backup_to_s3 ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.gitlab_backup[0].bucket}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListAllMyBuckets"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.gitlab_backup[0].bucket}"
    ]
  }
}

resource "aws_iam_policy" "gitlab_backup" {
  count  = var.enable_gitlab_backup_to_s3 ? 1 : 0
  name   = "gitlab-backup"
  policy = data.aws_iam_policy_document.gitlab_s3_backup[0].json
}

resource "aws_iam_role" "gitlab_backup" {
  name                = "gitlab-backup"
  assume_role_policy  = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
  managed_policy_arns = var.enable_gitlab_backup_to_s3 ? [aws_iam_policy.gitlab_backup[0].arn] : []
}

resource "aws_iam_instance_profile" "gitlab" {
  name = "gitlab"
  role = aws_iam_role.gitlab_backup.name
}
