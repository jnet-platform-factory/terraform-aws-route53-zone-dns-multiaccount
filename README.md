# terraform-aws-route53-zone-dns-multiaccount

Creates a public Route 53 hosted zone in a workload account, delegates it from a parent zone that lives in a
separate DNS account, issues a DNS-validated ACM certificate for it, and publishes the results to SSM.

What it creates:

- A hosted zone `hosted_zone_name` in the workload account (default `aws` provider).
- An `NS` record `ns_record_subdomain` in the existing zone `main_hosted_zone_name`, in the DNS account
  (`aws.dns` provider).
- An ACM certificate for `hosted_zone_name` plus `subject_alternative_names`, validated through the new zone.
- Three SSM parameters, listed below.

## Usage

The module needs two AWS providers: the default one for the workload account, and one aliased `dns` for the
account that owns the parent zone. With Terragrunt:

```hcl
terraform {
  source = "tfr:///jnet-platform-factory/route53-zone-dns-multiaccount/aws?version=0.2.0"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "aws" {
      alias  = "dns"
      region = "us-east-1"
      assume_role {
        role_arn = "arn:aws:iam::<dns-account-id>:role/<role-name>"
      }
    }
    provider "aws" {
      region = "us-east-1"
      assume_role {
        role_arn = "arn:aws:iam::<workload-account-id>:role/<role-name>"
      }
    }
EOF
}

inputs = {
  env                   = "dev"
  application           = "Infrastructure" # optional, see SSM parameters
  service               = "Platform/api"
  main_hosted_zone_name = "example.com"
  hosted_zone_name      = "api.example.com"
  ns_record_subdomain   = "api"
  subject_alternative_names = [
    "api.example.com",
    "*.api.example.com",
  ]
}
```

## Inputs

| Name                        | Description                                                                            | Type           | Default | Required |
| --------------------------- | -------------------------------------------------------------------------------------- | -------------- | ------- | :------: |
| `main_hosted_zone_name`     | Existing public parent zone in the DNS account that receives the NS delegation record. | `string`       | n/a     |   yes    |
| `hosted_zone_name`          | Zone to create in the workload account.                                                | `string`       | n/a     |   yes    |
| `ns_record_subdomain`       | Record name, relative to `main_hosted_zone_name`, for the NS delegation.               | `string`       | n/a     |   yes    |
| `subject_alternative_names` | Subject alternative names for the ACM certificate.                                     | `list(string)` | n/a     |   yes    |
| `env`                       | Environment name.                                                                      | `string`       | n/a     |   yes    |
| `service`                   | SSM path segment under which results are published.                                    | `string`       | n/a     |   yes    |
| `application`               | Optional SSM path prefix.                                                              | `string`       | `""`    |    no    |

## SSM parameters

The prefix is `/<application>/<service>` when `application` is set, and `/<service>` when it is empty.

| Parameter                      | Value                         |
| ------------------------------ | ----------------------------- |
| `<prefix>/acm_certificate_arn` | ARN of the issued certificate |
| `<prefix>/hosted_zone_id`      | ID of the created zone        |
| `<prefix>/hosted_zone_name`    | Name of the created zone      |

## Upgrading

- **From 0.1.0:** no changes. Keep passing `application`, and parameter names stay the same.
- **From 0.1.1:** no changes. Leave `application` unset, and parameter names stay the same.
