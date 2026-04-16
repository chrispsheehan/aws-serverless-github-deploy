data "aws_rds_engine_version" "postgres" {
  engine  = local.postgres_engine
  version = var.engine_version
  latest  = true
}

data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}
