# Terragrunt Graph Helpers

Use these commands when debugging stack ordering, workflow wave generation, or saved-plan metadata joins.

To return the direct dependencies for every module as a JSON object:

```sh
just tg-all-module-dependencies dev
```

To test the wave-matrix processor locally through the same split used by CI:

```sh
just tg-graph-waves dev
```

If you only need the raw Terragrunt graph output:

```sh
just tg-graph dev > graph.txt
```

That runs the same non-interactive Terragrunt graph command used in CI:

```sh
cd infra/live/dev/aws
terragrunt run-all graph-dependencies \
  --terragrunt-non-interactive \
  --terragrunt-include-external-dependencies
```

To process that saved graph file into compact dependency JSON:

```sh
just tg-graph-process graph.json dev
```

To return only changed saved-plan items as an object array, set the saved-plan env vars and run:

```sh
BUCKET_NAME=700060376888-eu-west-2-aws-serverless-github-deploy-tfplan \
TG_GRAPH_METADATA_PLAN_RUN_ID=26105102715 \
just tg-graph-changed-items graph.json dev
```

To join the processed graph with saved-plan metadata for one plan run, set the saved-plan env vars before running the processing command:

```sh
BUCKET_NAME=700060376888-eu-west-2-aws-serverless-github-deploy-tfplan \
TG_GRAPH_METADATA_PLAN_RUN_ID=26105102715 \
just tg-graph-process graph.json dev
```

For a local saved-plan run, pass the Terragrunt operation as one quoted argument:

```sh
just tg dev aws/oidc 'plan -out=terragrunt.tfplan'
```

The `tg` recipe treats the final argument as the Terragrunt operation string, so quoting lets you pass flags such as `-out=...` through the wrapper. The workflow saved-plan path expects the binary plan filename to be `terragrunt.tfplan`.

To apply that same saved plan later, reuse the same run id:

```sh
just tg dev aws/oidc 'apply terragrunt.tfplan'
```
