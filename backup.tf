/* Resources for setting up Gitlab remote backup on Amazon S3 */
locals {
  gitlab_backup_iam_policy_name = "${local.environment_prefix}-gitlab-backup"
  gitlab_backup_iam_role_name   = "${local.environment_prefix}-gitlab-backup"
}

resource "aws_s3_bucket" "gitlab_backup" {
  count  = var.enable_gitlab_backup_to_s3 ? 1 : 0
  bucket = var.gitlab_backup_bucket_name

  tags = merge(local.default_tags, var.additional_tags)

  aws_s3_bucket_public_access_block = {
    block_public_acls       = true
  }

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
  name   = local.gitlab_backup_iam_policy_name
  policy = data.aws_iam_policy_document.gitlab_s3_backup[0].json
  tags = merge({
    Name = local.gitlab_backup_iam_policy_name
  }, local.default_tags, var.additional_tags)
}

resource "aws_iam_role" "gitlab_backup" {
  name                = local.gitlab_backup_iam_role_name
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
  tags = merge({
    Name = local.gitlab_backup_iam_role_name
  }, local.default_tags, var.additional_tags)
}
