data "aws_iam_policy_document" "database_secret_read" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      var.database_credentials_secret_arn,
    ]
  }
}
