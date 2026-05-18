dependency "cluster" {
  config_path = "${get_original_terragrunt_dir()}/../cluster"

  mock_outputs = {
    cluster_id   = "mock-cluster-id"
    cluster_name = "mock-cluster"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show"]
}

inputs = {
  cluster_id   = dependency.cluster.outputs.cluster_id
  cluster_name = dependency.cluster.outputs.cluster_name
}
