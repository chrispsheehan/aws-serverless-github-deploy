dependency "database" {
  config_path = "${get_original_terragrunt_dir()}/../database"

  mock_outputs = {
    credentials_secret_arn = "arn:aws:secretsmanager:eu-west-2:111111111111:secret:mock-database-credentials"
    readwrite_endpoint     = "mock-database.cluster-abcdefghijkl.eu-west-2.rds.amazonaws.com"
    database_name          = "app"
    database_port          = 5432
    cluster_identifier     = "mock-database-cluster"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show"]
}

inputs = {
  database_credentials_secret_arn = dependency.database.outputs.credentials_secret_arn
  database_readwrite_endpoint     = dependency.database.outputs.readwrite_endpoint
  database_name                   = dependency.database.outputs.database_name
  database_port                   = dependency.database.outputs.database_port
  database_cluster_identifier     = dependency.database.outputs.cluster_identifier
}
