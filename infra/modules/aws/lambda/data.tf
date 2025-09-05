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