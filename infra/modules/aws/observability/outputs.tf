output "dashboard_name" {
  value = aws_cloudwatch_dashboard.observability.dashboard_name
}

output "dashboard_url" {
  value = local.dashboard_url
}
