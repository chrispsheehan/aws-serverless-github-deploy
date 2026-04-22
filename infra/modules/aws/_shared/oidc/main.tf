resource "aws_iam_openid_connect_provider" "github_actions" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.github_thumbprint]
  url             = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = var.deploy_role_name
  description          = "GitHub Actions OIDC role for ${var.github_repo} (${var.environment})."
  max_session_duration = var.max_session_duration
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "role_access" {
  statement {
    effect    = "Allow"
    actions   = var.allowed_role_actions
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions" {
  name        = "${var.deploy_role_name}-policy"
  description = "Runtime policy for the ${var.deploy_role_name} GitHub Actions OIDC role."
  policy      = data.aws_iam_policy_document.role_access.json
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
