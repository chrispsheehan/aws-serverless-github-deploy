data "aws_rds_engine_version" "postgres" {
  engine  = local.postgres_engine
  version = var.engine_version
  latest  = true
}

data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}

data "aws_secretsmanager_secret" "db_credentials" {
  arn = aws_rds_cluster.aurora_postgres.master_user_secret[0].secret_arn
}
