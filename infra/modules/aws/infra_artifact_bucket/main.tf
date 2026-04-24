module "infra_arrifact_bucket" {
  source = "../_shared/code_bucket"

  code_bucket        = var.infra_plan_artifact_bucket
  s3_expiration_days = var.infra_plan_artifact_days
}