# modules/services/static_site/main.tf

resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    Terraform   = "True"
  }
}

resource "aws_s3_bucket_ownership_controls" "enforce_object_ownership" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "allow_access_from_cloudfront_distribution" {
  count  = var.is_forwarded_site ? 0 : 1
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.allow_access_from_cloudfront_distribution[count.index].json
}

data "aws_iam_policy_document" "allow_access_from_cloudfront_distribution" {
  count = var.is_forwarded_site ? 0 : 1
  statement {
    sid = "AllowCloudFrontServicePrincipal"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.website.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_website_configuration" "redirect" {
  count  = var.is_forwarded_site ? 1 : 0
  bucket = aws_s3_bucket.website.id

  redirect_all_requests_to {
    host_name = "www.${var.domain_name}"
  }
}

resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name              = var.is_forwarded_site ? aws_s3_bucket_website_configuration.redirect[0].website_endpoint : aws_s3_bucket.website.bucket_regional_domain_name
    origin_access_control_id = var.is_forwarded_site ? null : aws_cloudfront_origin_access_control.website-default.id
    origin_id                = aws_s3_bucket.website.bucket_regional_domain_name

    dynamic "custom_origin_config" {
      for_each = var.is_forwarded_site ? [1] : []
      content {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [var.domain_alias]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.website.bucket_regional_domain_name

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    compress               = var.is_forwarded_site ? false : true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.is_forwarded_site ? data.aws_cloudfront_cache_policy.managed-cache-disabled.min_ttl : data.aws_cloudfront_cache_policy.managed-cache-optimized.min_ttl
    default_ttl            = var.is_forwarded_site ? data.aws_cloudfront_cache_policy.managed-cache-disabled.default_ttl : data.aws_cloudfront_cache_policy.managed-cache-optimized.default_ttl
    max_ttl                = var.is_forwarded_site ? data.aws_cloudfront_cache_policy.managed-cache-disabled.max_ttl : data.aws_cloudfront_cache_policy.managed-cache-optimized.max_ttl
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    Terraform   = "True"
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_route53_record" "website" {
  zone_id = var.route53_zone_id
  name    = var.domain_alias
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.website_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "website_ipv6" {
  zone_id = var.route53_zone_id
  name    = var.domain_alias
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.website_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.website_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_origin_access_control" "website-default" {
  name                              = "${var.bucket_name}-default"
  description                       = "Default OAI Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_cache_policy" "managed-cache-optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "managed-cache-disabled" {
  name = "Managed-CachingDisabled"
}
