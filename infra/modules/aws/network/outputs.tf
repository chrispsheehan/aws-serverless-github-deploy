output "default_target_group_arn" {
  value = aws_lb_target_group.default.arn
}

output "default_http_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "load_balancer_arn_suffix" {
  value = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.default.arn_suffix
}

output "internal_invoke_url" {
  value = "http://${aws_lb.this.dns_name}"
}
