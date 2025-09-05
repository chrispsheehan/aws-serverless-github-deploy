data "aws_s3_bucket" "lambda_code" {
  bucket = var.lambda_bucket
}

data "aws_s3_object" "lambda_code_zip" {
  bucket = data.aws_s3_bucket.lambda_code.bucket
  key    = local.lambda_code_zip
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
