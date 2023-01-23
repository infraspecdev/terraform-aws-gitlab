/* Resources for RDS setup */
locals {
  gitlab_rds_cluster_name = "${local.environment_prefix}-gitlab-pg"
  gitlab_rds_sg_name      = "${local.environment_prefix}-gitlab-rds"
}
resource "aws_security_group" "gitlab_rds" {
  name        = local.gitlab_rds_sg_name
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
  tags = merge({
    Name = local.gitlab_rds_sg_name
  }, local.default_tags, var.additional_tags)
}

module "gitlab_pg" {
  source                    = "terraform-aws-modules/rds/aws"
  identifier                = local.gitlab_rds_cluster_name
  create_db_instance        = true
  create_db_subnet_group    = true
  create_db_parameter_group = var.gitlab_pg_create_db_parameter_group
  parameter_group_name      = var.gitlab_pg_parameter_group_name
  parameters                = var.gitlab_pg_parameters
  db_subnet_group_name      = "${local.environment_prefix}-gitlab-pg"
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
  tags = merge({
    Name = local.gitlab_rds_cluster_name
  }, local.default_tags, var.additional_tags)
}
