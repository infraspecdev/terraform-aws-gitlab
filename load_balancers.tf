/* Resources for Gitlab classic load balancer */
resource "aws_security_group" "gitlab_lb" {
  name        = "${local.environment_prefix}-gitlab-lb"
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
  tags = merge({
    Name = "${local.environment_prefix}-gitlab-lb"
  }, local.default_tags, var.additional_tags)
}

module "elb" {
  source          = "terraform-aws-modules/elb/aws"
  version         = "~> 2.0"
  name            = "${local.environment_prefix}-gitlab"
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
  number_of_instances = 1
  instances           = tolist([aws_instance.gitlab.id])
  tags = merge({
    Name = "${local.environment_prefix}-gitlab"
  }, local.default_tags, var.additional_tags)
}
