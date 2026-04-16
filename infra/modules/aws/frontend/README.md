# `frontend`

Static frontend hosting module.

## Owns

- website bucket and distribution resources
- bootstrap `index.html` object for first-time infra deploys
- `auth-config.json` for runtime Cognito/frontend configuration
- ACM certificate and Route53 alias records for the derived CloudFront custom domain
- deployment destination for built frontend assets
- path-based forwarding of `/api/*` requests to the shared API origin

## Routing behavior

- `/auth-config.json`
  served from the frontend bucket with caching disabled so auth configuration changes are visible immediately
- `/api/*`
  forwarded to API Gateway, stripped to `/*`, and forwards the `Authorization` header for Cognito-backed JWT auth
- `/api/ecs/*`
  forwarded to API Gateway, stripped to `/ecs/*`, and forwards the `Authorization` header for Cognito-backed JWT auth
- all other paths
  served from the frontend bucket with SPA routing

## Custom domain

The module expects `domain_name` and derives the deployed frontend URL as `<project_name>.<environment>.<domain_name>`.
It requests an ACM certificate in `us-east-1`, validates it with Route53 DNS records, and creates `A` and `AAAA` alias records in the matching hosted zone.
If `frontend_hosted_zone_name` is omitted, the module uses `domain_name` itself as the hosted zone, which fits names like `aws-serverless-github-deploy.dev.chrispsheehan.com`.

## Key outputs

- website bucket name
- CloudFront distribution id

Used by the frontend build and deploy workflow path.

The Terraform module uploads a bootstrap `index.html` so the distribution serves a valid page before the built frontend assets are published. Later frontend deploys replace that object with the real app bundle output.
