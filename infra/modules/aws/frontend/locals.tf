locals {
  name        = "${var.environment}-${var.project_name}"
  bucket_name = "${data.aws_caller_identity.current.account_id}-${local.name}"
  api_domain  = replace(data.terraform_remote_state.api.outputs.invoke_url, "https://", "")

  s3_origin_id  = "s3"
  api_origin_id = "api"

  root_file                  = "index.html"
  caching_optimized_id       = "Managed-CachingOptimized"
  origin_request_policy_id   = "Managed-CORS-S3Origin"
  response_headers_policy_id = "Managed-CORS-With-Preflight"
  caching_disabled_id        = "Managed-CachingDisabled"
}
