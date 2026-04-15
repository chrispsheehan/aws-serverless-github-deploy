data "aws_rds_engine_version" "postgres" {
  engine  = local.postgres_engine
  version = var.engine_version
}

data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  filter {
    name   = "tag:Name"
    values = [var.publicly_accessible ? "*public*" : "*private*"]
  }
}

data "aws_subnet" "selected" {
  for_each = toset(data.aws_subnets.this.ids)
  id       = each.value
}

data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}
