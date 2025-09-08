data "aws_s3_bucket" "lambda_code" {
  bucket = var.lambda_bucket
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

data "aws_iam_policy_document" "code_deploy_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codedeploy_lambda" {
  statement {
    sid    = "LambdaControl"
    effect = "Allow"
    actions = [
      "lambda:GetFunction",
      "lambda:PublishVersion",
      "lambda:GetAlias",
      "lambda:CreateAlias",
      "lambda:UpdateAlias",
      "lambda:ListAliases",
      "lambda:ListVersionsByFunction",
    ]
    resources = [
      aws_lambda_function.lambda.arn,
      "${aws_lambda_function.lambda.arn}:*",
    ]
  }

  statement {
    sid     = "ReadArtifactObject"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = [
      "arn:aws:s3:::${data.aws_s3_bucket.lambda_code.bucket}/${local.lambda_code_zip_key}",
      "arn:aws:s3:::${data.aws_s3_bucket.lambda_code.bucket}/${var.lambda_version}/*"
    ]
  }

  # Allow listing the bucket for that prefix (some SDKs call this)
  statement {
    sid       = "ListArtifactPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${data.aws_s3_bucket.lambda_code.bucket}"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.lambda_version}/*"]
    }
  }

  statement {
    sid       = "DescribeAlarms"
    effect    = "Allow"
    actions   = ["cloudwatch:DescribeAlarms"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "lambda_iam_policy" {
  statement {
    sid = "AllowLambdaCloudwatchLogGroupPut"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    effect = "Allow"

    resources = [
      "${aws_cloudwatch_log_group.lambda_cloudwatch_group.arn}",
      "${aws_cloudwatch_log_group.lambda_cloudwatch_group.arn}:*"
    ]
  }
}