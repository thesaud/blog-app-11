output "frontend_bucket_name" {
  value       = aws_s3_bucket.frontend_bucket.bucket
  description = "Name of the frontend S3 bucket"
}

output "frontend_bucket_website_endpoint" {
  value       = aws_s3_bucket_website_configuration.frontend_website.website_endpoint
  description = "Website endpoint for the frontend S3 bucket"
}

output "media_bucket_name" {
  value       = aws_s3_bucket.media_bucket.bucket
  description = "Name of the media S3 bucket"
}

output "media_bucket_domain_name" {
  value       = aws_s3_bucket.media_bucket.bucket_domain_name
  description = "Domain name of the media S3 bucket"
}

output "media_bucket_url" {
  value       = "https://${aws_s3_bucket.media_bucket.bucket_regional_domain_name}"
  description = "URL of the media S3 bucket"
}

output "ec2_instance_id" {
  value       = aws_instance.backend_instance.id
  description = "ID of the EC2 instance"
}

output "ec2_public_ip" {
  value       = aws_instance.backend_instance.public_ip
  description = "Public IP of the EC2 instance"
}

output "s3_user_access_key" {
  value       = aws_iam_access_key.s3_user_key.id
  description = "Access key for the IAM user"
  sensitive   = true
}

output "s3_user_secret_key" {
  value       = aws_iam_access_key.s3_user_key.secret
  description = "Secret key for the IAM user"
  sensitive   = true
} 