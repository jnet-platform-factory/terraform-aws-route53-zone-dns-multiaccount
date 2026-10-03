variable "subject_alternative_names" {
  description = "Subject alternative names for the ACM certificate issued for hosted_zone_name."
  type        = list(string)
}

variable "main_hosted_zone_name" {
  description = "Existing public parent zone in the DNS account that receives the NS delegation record, e.g. example.com."
  type        = string
}

variable "hosted_zone_name" {
  description = "Zone to create in the workload account, e.g. api.example.com."
  type        = string
}

variable "ns_record_subdomain" {
  description = "Record name, relative to main_hosted_zone_name, for the NS delegation, e.g. api."
  type        = string
}

variable "env" {
  description = "Environment name."
  type        = string
}

variable "application" {
  description = "Optional SSM path prefix. When set, parameters are written under /<application>/<service>/; when empty, under /<service>/."
  type        = string
  default     = ""
}

variable "service" {
  description = "SSM path segment under which the certificate ARN and zone ID/name are published."
  type        = string
}
