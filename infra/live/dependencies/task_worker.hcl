dependency "task_worker" {
  config_path = "${get_original_terragrunt_dir()}/../task_worker"

  mock_outputs = {
    task_definition_arn = "arn:aws:ecs:eu-west-2:111111111111:task-definition/mock-task-worker:1"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show"]
}

inputs = {
  task_definition_arn = dependency.task_worker.outputs.task_definition_arn
}
