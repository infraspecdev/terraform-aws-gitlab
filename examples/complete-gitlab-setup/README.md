# Complete Gitlab
Configuration in this directory creates a complete single instance Gitlab omnibus setup.

## Usage
To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which can cost money (AWS Elastic IP, for example). Run `terraform destroy` when you don't need these resources.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.40 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gitlab"></a> [gitlab](#module\_gitlab) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_private_key"></a> [private\_key](#input\_private\_key) | Private key to execute ansible playbook on Gitlab instance. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gitlab_pg_address"></a> [gitlab\_pg\_address](#output\_gitlab\_pg\_address) | Gitlab Postgres address |
| <a name="output_gitlab_redis_address"></a> [gitlab\_redis\_address](#output\_gitlab\_redis\_address) | Gitlab Redis address |
| <a name="output_gitlab_url"></a> [gitlab\_url](#output\_gitlab\_url) | Gitlab url including the url schema |
<!-- END_TF_DOCS -->
