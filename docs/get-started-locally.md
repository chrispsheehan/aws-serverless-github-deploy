# Get Started Locally

Use this for local stack commands, common local commands, AWS prerequisites, and runtime task links.

## Local Stack

Start the local stack:

```sh
just start
```

This starts local PostgreSQL, queue emulation, Lambda/ECS runtimes, migrations, the frontend dev server, and log tailing.

Stop the local stack and remove Compose volumes:

```sh
just stop
```

Run only the frontend dev server:

```sh
just frontend
```

Local service notes:

- frontend dev server and local API proxy: [frontend](../frontend/README.md)
- Lambda runtime layout and local watch behavior: [lambdas](../lambdas/README.md)
- ECS runtime layout and local watch behavior: [containers](../containers/README.md)
- Lambda worker local queue publishing: [lambdas/lambda_worker](../lambdas/lambda_worker/README.md)
- ECS worker local queue publishing and database verification: [containers/worker](../containers/worker/README.md)

## Prerequisites

The AWS account must already have the landing-zone or StackSet network in place before deploying this repo.

- the Terraform in this repo reads the VPC and subnets with `data` sources rather than creating them
- the expected VPC and subnets must therefore already exist
- the private subnets must be tagged so the module lookups can find them, for example with names matching `*private*`
- if you plan to deploy the frontend custom domain, the matching Route53 hosted zone must also already exist
- the S3 Terraform state bucket should have bucket versioning enabled, because the repo uses the [Terraform S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3) lockfile path rather than DynamoDB state locking

If those shared network or DNS resources do not exist yet, the infra applies in this repo will fail during data lookup or certificate/DNS creation.

Required shared prerequisites before a full environment deploy:

- pre-existing VPC
- tagged private subnets that the data lookups can resolve
- Route53 hosted zone for the deployed frontend domain when using the frontend custom domain path

## One-Time CI Role Bootstrap

Before GitHub Actions can plan, apply, or deploy, bootstrap the GitHub OIDC roles once per environment:

```sh
just tg ci aws/oidc apply
just tg dev aws/oidc apply
just tg prod aws/oidc apply
```

Run these with local AWS credentials that can create or update IAM roles and policies.

After the roles exist, normal CI/CD workflows assume them through GitHub OIDC, and CI can update the roles when the OIDC module, trust policy, or allowed AWS permissions change.

The `ci` OIDC role is intentionally narrower than the `dev` and `prod` roles. Detailed scope lives in [OIDC module docs](../infra/modules/aws/_shared/oidc/README.md).

Routing and runtime feasibility contracts:

- [network](../infra/modules/aws/network/README.md)
- [frontend](../infra/modules/aws/frontend/README.md)
- [shared ECS service](../infra/modules/aws/_shared/service/README.md)
- [shared ECS task](../infra/modules/aws/_shared/task/README.md)

## Common Tasks

The root [`justfile`](../justfile) keeps local developer commands.

Split recipe files:

- CI-only helpers: [`justfile.ci`](../justfile.ci)
- CI build/deploy helpers: [`justfile.deploy`](../justfile.deploy)

Run split files locally with `--justfile`:

```sh
just --justfile justfile.ci tf-lint-check
just --justfile justfile.deploy lambda-get-version
just --justfile justfile.deploy frontend-build
```

Given a Terragrunt file is found at `infra/live/dev/aws/lambda_api/terragrunt.hcl`:

```sh
just tg dev aws/lambda_api plan
```

Terragrunt graph and saved-plan helper commands live in [Terragrunt Graph Helpers](../infra/docs/terragrunt-graph-helpers.md).

Placeholder app runtime tasks live with the code that owns them:

- Lambda API message publishing: [lambdas/lambda_api](../lambdas/lambda_api/README.md)
- Lambda worker queue publishing: [lambdas/lambda_worker](../lambdas/lambda_worker/README.md)
- ECS worker publishing, database verification, and debug shells: [containers/worker](../containers/worker/README.md)
- Database migration runtime and invocation: [lambdas/migrations](../lambdas/migrations/README.md)
- Frontend auth and API proxy behavior: [frontend](../frontend/README.md)
