output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app.public_ip
}


output "ecr_app_url" {
  description = "ECR repository URL for the Flask app"
  value       = aws_ecr_repository.app.repository_url
}


output "ecr_mysql_url" {
  description = "ECR repository URL for MySQL"
  value       = aws_ecr_repository.mysql.repository_url
}


output "aws_region" {
  description = "AWS region for ECR login"
  value       = var.aws_region
}
