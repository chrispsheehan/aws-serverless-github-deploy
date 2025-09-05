locals {
  lambda_runtime = "python3.12"

  lambda_handler  = "${var.lambda_name}.lambda_handler"
  lambda_name     = "${var.environment}-${var.project_name}-${var.lambda_name}"
  lambda_code_zip = "${var.version}/${var.lambda_name}.zip"
}