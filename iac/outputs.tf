
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "ecr_repository_url" {
  description = "URL of the ECR repository for backend"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.backend.name
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_hosted_zone_id" {
  description = "Hosted zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "backend_api_url" {
  description = "URL of the backend API"
  value       = "https://${aws_lb.main.dns_name}"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the frontend"
  value       = aws_s3_bucket.frontend.id
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.frontend.bucket_domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "frontend_url" {
  description = "URL of the frontend application"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = var.enable_monitoring ? "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main[0].dashboard_name}" : "Monitoring disabled"
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = var.notification_email != "" ? aws_sns_topic.alerts[0].arn : "No email configured"
}

output "deployment_info" {
  description = "Information needed for deployment"
  value = {
    ecr_repository_url = aws_ecr_repository.backend.repository_url
    ecs_cluster_name   = aws_ecs_cluster.main.name
    ecs_service_name   = aws_ecs_service.backend.name
    s3_bucket_name     = aws_s3_bucket.frontend.id
    cloudfront_dist_id = aws_cloudfront_distribution.frontend.id
    backend_api_url    = "https://${aws_lb.main.dns_name}"
    frontend_url       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
  }
}