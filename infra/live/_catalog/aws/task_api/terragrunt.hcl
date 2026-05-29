include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependencies {
  paths = ["../security", "../cluster", "../network"]
}

terraform {
  source = "../../../../modules//aws//task_api"
}
