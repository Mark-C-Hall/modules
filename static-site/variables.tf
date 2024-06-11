variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "domain_alias" {
  description = "The domain alias for the CloudFront distribution"
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate"
  type        = string
}

variable "route53_zone_id" {
  description = "The Route53 Zone ID"
  type        = string
}

variable "environment" {
  description = "The environment of the deployment"
  type        = string
  default     = "Production"
}

variable "is_forwarded_site" {
  description = "Boolean to indicate if the site is forwarding to another site"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "The domain name for the redirection"
  type        = string
}
