output "lambda_function_name" {
  value = module.rds_reader_tagger.function_name
}

output "lambda_alias_name" {
  value = module.rds_reader_tagger.alias_name
}

output "cloudwatch_log_group" {
  value = module.rds_reader_tagger.cloudwatch_log_group
}

output "event_rule_name" {
  value = aws_cloudwatch_event_rule.reader_instance_created.name
}
