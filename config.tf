/* Resources for management of gitlab.rb from within the terraform module itself using Ansible playbooks */

locals {
  gitlab_config_file_name            = "gitlab.rb"
  rendered_gitlab_config_file_name   = "gitlab_rendered.rb"
  gitlab_additional_config_file_name = "gitlab_additional.rb"
  gitlab_config_tmp_path             = "/tmp/gitlab/gitlab_config"
  gitlab_config_template_file_path   = "${path.module}/templates"
  gitlab_config_file_path            = "${path.cwd}/gitlab_config"
  gitlab_config_playbook_file        = "${path.module}/playbooks/gitlab_setup.yaml"
  gitlab_complete_url                = join("", tolist(["https://", values(module.records.route53_record_name)[0]]))
}

data "template_file" "gitlab_config_template" {
  template = join("\n", [
    file("${local.gitlab_config_template_file_path}/postgres.tftpl"),
    file("${local.gitlab_config_template_file_path}/redis.tftpl"),
    file("${local.gitlab_config_template_file_path}/nginx.tftpl"),
    file("${local.gitlab_config_template_file_path}/rails.tftpl"),
    var.create_ses_identity ? file("${local.gitlab_config_template_file_path}/smtp.tftpl") : "",
  ])
  vars = merge({
    gitlab_url                   = local.gitlab_complete_url,
    gitlab_db_name               = module.gitlab_pg.db_instance_name,
    gitlab_db_username           = module.gitlab_pg.db_instance_username,
    gitlab_db_password           = module.gitlab_pg.db_instance_password,
    gitlab_db_host               = module.gitlab_pg.db_instance_address,
    gitlab_redis_host            = aws_elasticache_cluster.gitlab_redis.cache_nodes[0].address,
    aws_region                   = aws_s3_bucket.gitlab_backup[0].region,
    gitlab_backup_s3_bucket_name = aws_s3_bucket.gitlab_backup[0].bucket
    }, var.create_ses_identity ? {
    smtp_address  = "email-smtp.${var.aws_region}.amazonaws.com",
    smtp_username = aws_iam_access_key.gitlab_smtp_user[0].id,
    smtp_password = aws_iam_access_key.gitlab_smtp_user[0].ses_smtp_password_v4,
    smtp_domain   = data.aws_route53_zone.email_domain[0].name
  } : {})
}

resource "local_sensitive_file" "rendered_gitlab_config_file" {
  filename = "${local.gitlab_config_tmp_path}/${local.rendered_gitlab_config_file_name}"
  content  = data.template_file.gitlab_config_template.rendered
}

data "local_sensitive_file" "gitlab_additional_config" {
  count    = fileexists("${local.gitlab_config_file_path}/${local.gitlab_additional_config_file_name}") ? 1 : 0
  filename = "${local.gitlab_config_file_path}/${local.gitlab_additional_config_file_name}"
}

resource "local_sensitive_file" "gitlab_config_file" {
  filename = "${local.gitlab_config_tmp_path}/${local.gitlab_config_file_name}"
  content = join("\n", tolist([
    data.template_file.gitlab_config_template.rendered,
    data.local_sensitive_file.gitlab_additional_config != [] ? data.local_sensitive_file.gitlab_additional_config[0].content : ""
  ]))
}

/*
  Adding null_resource trigger on timestamp is a hack to always check the diff in the
  config if any and apply the config changes to Gitlab.
*/
resource "null_resource" "gitlab_reconfigure" {
  triggers = {
    timestamp = timestamp()
  }
  provisioner "local-exec" {
    command = "ansible-playbook -u ubuntu -i '${aws_instance.gitlab.private_ip},' --private-key ${var.private_key} -e 'instance_ip_address=${aws_instance.gitlab.private_ip} workdir=${local.gitlab_config_tmp_path} config_file=${local_sensitive_file.gitlab_config_file.filename}' ${local.gitlab_config_playbook_file}"
  }
}
