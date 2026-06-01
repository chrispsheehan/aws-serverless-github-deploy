# ECS Connection Types

Choose connection type based on how the ECS service should be reached.

## `internal`

- use for internal services without API Gateway or shared-ALB traffic switching
- prefer `rolling`
- this shape is not compatible with this repo's ECS CodeDeploy path

## `internal_dns`

- use for load-balanced internal services that should be addressable through the shared internal ALB and DNS path
- supports ECS CodeDeploy in this repo

## `vpc_link`

- use for HTTP services exposed through the shared API Gateway via VPC link
- supports ECS CodeDeploy in this repo
- if JWT auth is enabled, the shared API Gateway authorizer is attached in this service shape
- task public IP assignment is not part of the inbound path; API Gateway still reaches the internal ALB through the VPC link, and the ALB targets task private IPs

## Feasibility Notes

- ECS CodeDeploy requires a load-balanced service shape in this repo
- in practice that means `connection_type` must be `internal_dns` or `vpc_link` for CodeDeploy-backed ECS deploys
- in this repo, subpath ECS services need a dedicated ALB listener if they are meant to use CodeDeploy blue/green
- if `connection_type = "internal"`, prefer `rolling`
- for internal non-load-balanced services, the deploy workflow falls back to native ECS rolling updates
