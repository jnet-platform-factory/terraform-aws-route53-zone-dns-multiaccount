locals {
  ssm_prefix = var.application != "" ? "/${var.application}/${var.service}" : "/${var.service}"
}

module "zone" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 2.0"
  zones = {
    "${var.hosted_zone_name}" = {
      comment = "${var.hosted_zone_name}"
    },
  }
}

module "ns_record_4_main" {
  depends_on = [module.zone]
  providers = {
    aws = aws.dns
  }
  source    = "terraform-aws-modules/route53/aws//modules/records"
  version   = "~> 2.0"
  zone_name = data.aws_route53_zone.main.name
  records = [
    {
      name    = "${var.ns_record_subdomain}"
      type    = "NS"
      ttl     = "300"
      records = module.zone.route53_zone_name_servers["${var.hosted_zone_name}"]
    },
  ]
}

module "acm" {
  depends_on = [module.zone, module.ns_record_4_main]
  source     = "git::https://github.com/terraform-aws-modules/terraform-aws-acm.git//?ref=master"

  domain_name       = var.hosted_zone_name
  zone_id           = module.zone.route53_zone_zone_id[var.hosted_zone_name]
  validation_method = "DNS"

  create_certificate     = true
  validate_certificate   = true
  wait_for_validation    = true
  create_route53_records = true

  subject_alternative_names = var.subject_alternative_names
}

module "ssm_params" {
  depends_on = [module.ns_record_4_main, module.acm]
  source     = "birkoff/ssm-params/aws"
  parameters = {
    acm_certificate_arn = {
      name  = "${local.ssm_prefix}/acm_certificate_arn"
      value = module.acm.acm_certificate_arn
    }
    hosted_zone_id = {
      name  = "${local.ssm_prefix}/hosted_zone_id"
      value = module.zone.route53_zone_zone_id[var.hosted_zone_name]
    }
    hosted_zone_name = {
      name  = "${local.ssm_prefix}/hosted_zone_name"
      value = module.zone.route53_zone_name[var.hosted_zone_name]
    }
  }
}
