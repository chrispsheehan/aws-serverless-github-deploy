include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  allowed_role_actions = [
    "s3:*",
    "iam:*"
  ]
  deploy_tags = ["*"]
}

inputs = {
  allowed_role_actions = local.allowed_role_actions
  deploy_tags          = local.deploy_tags
}

terraform {
  source = "tfr:///chrispsheehan/github-oidc-role/aws?version=0.2.2"
}
