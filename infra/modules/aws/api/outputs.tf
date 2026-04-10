output "invoke_url" {
  value = data.terraform_remote_state.network.outputs.api_invoke_url
}

output "api_id" {
  value = data.terraform_remote_state.network.outputs.api_id
}

output "vpc_link_id" {
  value = data.terraform_remote_state.network.outputs.vpc_link_id
}

output "cloudwatch_log_group" {
  value = module.lambda_api.cloudwatch_log_group
}

output "lambda_arn" {
  value = module.lambda_api.arn
}

output "lambda_function_name" {
  value = module.lambda_api.function_name
}

output "lambda_alias_name" {
  value = module.lambda_api.alias_name
}
