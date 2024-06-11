output "s3_bucket_arn" {
  value       = aws_s3_bucket.website.arn
  description = "The ARN of the S3 bucket"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.website_distribution.id
  description = "The ID of the CloudFront distribution"
}
