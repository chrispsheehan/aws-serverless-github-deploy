# aws-serverless-github-deploy

**Terraform + GitHub Actions for AWS serverless deployments.**  
Lambda + ECS with CodeDeploy rollouts, plus provisioned concurrency controls for Lambda — driven by clean module variables and `just` recipes.

## Overview

- Terraform/Terragrunt stacks for a typical AWS application shape: APIs, workers, frontend, database, auth, and messaging
- GitHub Actions workflows for infrastructure apply, artifact build, code deploy, and destroy
- shared deployment patterns for Lambda and ECS, with repo-local `just` commands for local and CI operations
- runtime and infrastructure layouts designed to be extended without having to rediscover the whole repo each time

## Bootstrap-Friendly Plans

This repo uses Terragrunt `dependency` wiring and plan-time mocks for bootstrap-sensitive cross-stack contracts.
See [infra/README.md](infra/README.md#dependency-notes) for the dependency strategy, mock-output rules, and saved-plan caveats.

Use [CONTRIBUTING.md](CONTRIBUTING.md) for expectations when changing the repo itself.

## Get Started Locally

Local stack commands, common `just` tasks, AWS prerequisites, and OIDC bootstrap commands live in [Get Started Locally](docs/get-started-locally.md).

## Infra Deployment Use Cases

For focused infra changes such as:

- upgrading the database
- changing a Lambda env var
- adding an API route
- changing a security group

see [infra/README.md](infra/README.md#infra-deployment-use-cases).

## Reference

For Lambda provisioned concurrency patterns and example `provisioned_config` shapes, see:

- [infra/modules/aws/_shared/lambda/README.md](infra/modules/aws/_shared/lambda/README.md)

For ECS scaling patterns and `scaling_strategy` examples, see:

- [infra/modules/aws/_shared/service/README.md](infra/modules/aws/_shared/service/README.md)

For the deployment model, runtime rollout split, and strategy overview, see:

- [infra/docs/deployment-model.md](infra/docs/deployment-model.md)

## Read This Next

- CI contracts and feasibility checks: [.github/docs/README.md](.github/docs/README.md)
- Lambda source layout: [lambdas/README.md](lambdas/README.md)
- Container source layout: [containers/README.md](containers/README.md)
- Frontend source layout and local proxy: [frontend/README.md](frontend/README.md)
- Infra layout and stack glossary: [infra/README.md](infra/README.md)
- OIDC role ownership and setup contract: [infra/modules/aws/_shared/oidc/README.md](infra/modules/aws/_shared/oidc/README.md)
- Shared Lambda deployment and provisioned concurrency behavior: [infra/modules/aws/_shared/lambda/README.md](infra/modules/aws/_shared/lambda/README.md)
- Shared ECS deployment and scaling behavior: [infra/modules/aws/_shared/service/README.md](infra/modules/aws/_shared/service/README.md)
- Shared network and routing surface: [infra/modules/aws/network/README.md](infra/modules/aws/network/README.md)
- Frontend auth contract: [infra/modules/aws/cognito/README.md](infra/modules/aws/cognito/README.md)
- Frontend hosting contract: [infra/modules/aws/frontend/README.md](infra/modules/aws/frontend/README.md)
- Runtime log dashboard: [infra/modules/aws/observability/README.md](infra/modules/aws/observability/README.md)
- Get started locally, prerequisites, and bootstrap commands: [docs/get-started-locally.md](docs/get-started-locally.md)
