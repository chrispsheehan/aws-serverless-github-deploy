locals {
  deploy_branches       = ["*"]
  image_expiration_days = 30
  force_delete          = true
}

inputs = {
  deploy_branches       = local.deploy_branches
  image_expiration_days = local.image_expiration_days
  force_delete          = local.force_delete
}
