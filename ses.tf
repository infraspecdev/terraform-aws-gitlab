/* Resources for Amazon SES setup to be used as SMTP service for Gitlab */
locals {
  gitlab_ses_sender_name = "${local.environment_prefix}-gitlab-ses-sender"
}
data "aws_route53_zone" "email_domain" {
  count = var.create_ses_identity ? 1 : 0
  name  = var.ses_domain != null ? var.ses_domain : var.hosted_zone
}

resource "aws_ses_domain_identity" "email_domain" {
  count  = var.create_ses_identity ? 1 : 0
  domain = data.aws_route53_zone.email_domain[0].name
}

resource "aws_route53_record" "email_domain_amazonses_verification_record" {
  count   = var.create_ses_identity ? 1 : 0
  zone_id = data.aws_route53_zone.email_domain[0].zone_id
  name    = "_amazonses.${aws_ses_domain_identity.email_domain[0].id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.email_domain[0].verification_token]
}

resource "aws_ses_domain_identity_verification" "email_domain_verification" {
  count      = var.create_ses_identity ? 1 : 0
  domain     = aws_ses_domain_identity.email_domain[0].id
  depends_on = [aws_route53_record.email_domain_amazonses_verification_record[0]]
}

resource "aws_iam_user" "gitlab_smtp_user" {
  count = var.create_ses_identity ? 1 : 0
  name  = var.ses_username
  tags  = merge(local.default_tags, var.additional_tags)
}

resource "aws_iam_access_key" "gitlab_smtp_user" {
  count = var.create_ses_identity ? 1 : 0
  user  = aws_iam_user.gitlab_smtp_user[0].name
}

data "aws_iam_policy_document" "gitlab_ses_sender" {
  count = var.create_ses_identity ? 1 : 0
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = [aws_ses_domain_identity.email_domain[0].arn]
  }
}

resource "aws_iam_policy" "gitlab_ses_sender" {
  count       = var.create_ses_identity ? 1 : 0
  name        = local.gitlab_ses_sender_name
  description = "Allows sending of e-mails via Simple Email Service"
  policy      = data.aws_iam_policy_document.gitlab_ses_sender[0].json
  tags = merge({
    Name = local.gitlab_ses_sender_name
  }, local.default_tags, var.additional_tags)
}

resource "aws_iam_user_policy_attachment" "gitlab_ses_sender" {
  count      = var.create_ses_identity ? 1 : 0
  user       = aws_iam_user.gitlab_smtp_user[0].name
  policy_arn = aws_iam_policy.gitlab_ses_sender[0].arn
}
