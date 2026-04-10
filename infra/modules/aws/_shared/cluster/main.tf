resource "aws_ecs_cluster" "this" {
  name = local.cluster_name
}
