data "aws_rds_engine_version" "postgres" {
  engine  = local.postgres_engine
  version = var.engine_version
  latest  = true
}

data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}

data "aws_iam_policy_document" "restore_drill_sfn_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "restore_drill_sfn" {
  statement {
    sid    = "RestoreAndDescribeRds"
    effect = "Allow"
    actions = [
      "rds:CreateDBInstance",
      "rds:DeleteDBCluster",
      "rds:DeleteDBInstance",
      "rds:DescribeDBClusters",
      "rds:DescribeDBInstances",
      "rds:RestoreDBClusterToPointInTime",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "restore_drill_scheduler_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "restore_drill_scheduler" {
  statement {
    sid    = "StartRestoreDrillExecution"
    effect = "Allow"
    actions = [
      "states:StartExecution",
    ]
    resources = aws_sfn_state_machine.restore_drill[*].arn
  }
}
