locals {
  default_tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
  environment_prefix           = substr(var.environment, 0, 1)
  gitlab_instance_name         = "${local.environment_prefix}-gitlab"
  gitlab_ssh_key_name          = "${local.environment_prefix}-gitlab-key-pair"
  gitlab_instance_sg_name      = "${local.environment_prefix}-gitlab"
  gitlab_instance_profile_name = "${local.environment_prefix}-gitlab"
}

resource "aws_instance" "gitlab" {
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
    iops                  = var.volume_iops
    delete_on_termination = false
  }

  tags = merge({
    Name = local.gitlab_instance_name
  }, local.default_tags, var.additional_tags)

}

resource "aws_key_pair" "gitlab_ssh" {
  count      = var.gitlab_ssh_public_key != null ? 1 : 0
  key_name   = local.gitlab_ssh_key_name
  public_key = var.gitlab_ssh_public_key
  tags = merge({
    Name = local.gitlab_ssh_key_name
  }, local.default_tags, var.additional_tags)
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_route53_zone" "zone" {
  name = var.hosted_zone
}

resource "aws_security_group" "gitlab" {
  name        = local.gitlab_instance_sg_name
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
  tags = merge({
    Name = local.gitlab_instance_sg_name
  }, local.default_tags, var.additional_tags)
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

  tags = merge({
    Name = var.gitlab_domain
  }, local.default_tags, var.additional_tags)
}

resource "aws_iam_instance_profile" "gitlab" {
  name = local.gitlab_instance_profile_name
  role = aws_iam_role.gitlab_backup.name
  tags = merge({
    Name = local.gitlab_instance_profile_name
  }, local.default_tags, var.additional_tags)
}
