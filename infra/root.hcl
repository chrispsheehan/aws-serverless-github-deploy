locals {
  github_token = get_env("GITHUB_TOKEN", "not_set")

  git_remote     = run_cmd("--terragrunt-quiet", "git", "remote", "get-url", "origin")
  github_repo    = regex("[/:]([-0-9_A-Za-z]*/[-0-9_A-Za-z]*)[^/]*$", local.git_remote)[0]
  repo_owner     = split("/", local.github_repo)[0]
  aws_account_id = get_aws_account_id()

  path_parts  = split("/", get_terragrunt_dir())
  module      = local.path_parts[length(local.path_parts) - 1]
  provider    = local.path_parts[length(local.path_parts) - 2]
  environment = local.path_parts[length(local.path_parts) - 3]

  global_vars      = read_terragrunt_config(find_in_parent_folders("global_vars.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment_vars.hcl"))

  project_name = element(split("/", local.github_repo), 1)

  aws_region       = local.global_vars.inputs.aws_region
  base_reference   = "${local.aws_account_id}-${local.aws_region}-${local.project_name}"
  deploy_role_name = "${local.project_name}-${local.environment}-github-oidc-role"
  state_bucket     = "${local.base_reference}-tfstate"
  state_key        = "${local.environment}/${local.provider}/${local.module}/terraform.tfstate"
  state_lock_table = "${local.project_name}-tf-lockid"

  # separate s3 version bucket when dev, otherwise ci
  s3_bucket_base = local.environment == "dev" ? "${local.base_reference}-${local.environment}" : "${local.base_reference}-ci"
  lambda_bucket  = "${local.s3_bucket_base}-lambda"

  lambda_name     = local.environment == "prod" ? local.project_name : "${local.environment}-${local.project_name}"
  lambda_api_name = "${local.lambda_name}-api"
}

terraform {
  before_hook "print_locals" {
    commands = ["init"]
    execute = [
      "bash", "-c", "echo STATE:${local.state_bucket}/${local.state_key} TABLE:${local.state_lock_table}"
    ]
  }
}

remote_state {
  backend = "s3"
  config = {
    bucket         = local.state_bucket
    key            = local.state_key
    region         = local.aws_region
    dynamodb_table = local.state_lock_table
    encrypt        = true
  }
}

generate "versions" {
  # this allows individual provider versioning for local modules
  path      = "versions.tf"
  if_exists = "skip"
  contents  = ""
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "skip"
  contents  = <<EOF
terraform {
  backend "s3" {}
}
EOF
}

generate "aws_provider" {
  path      = "provider_aws.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region              = "${local.aws_region}"
  allowed_account_ids = ["${local.aws_account_id}"]
  default_tags {
    tags = {
      Project     = "${local.project_name}"
      Environment = "${local.environment}"
    }
  }
}
EOF
  disable   = local.provider != "aws"
}

inputs = merge(
  local.global_vars.inputs,
  local.environment_vars.inputs,
  {
    aws_account_id   = local.aws_account_id
    aws_region       = local.aws_region
    project_name     = local.project_name
    environment      = local.environment
    github_repo      = local.github_repo
    deploy_role_name = local.deploy_role_name
    state_bucket     = local.state_bucket
    state_lock_table = local.state_lock_table
    lambda_bucket    = local.lambda_bucket
    lambda_api_name  = local.lambda_api_name
  }
)
