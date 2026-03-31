locals {
  deploy_branches       = ["*"]
  image_expiration_days = 30
}

inputs = {
  deploy_branches       = local.deploy_branches
  image_expiration_days = local.image_expiration_days
}
