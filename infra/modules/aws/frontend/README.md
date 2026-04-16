# `frontend`

Static frontend hosting module.

## Owns

- website bucket and distribution resources
- bootstrap `index.html` object for first-time infra deploys
- `auth-config.json` for runtime Cognito/frontend configuration
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

## Key outputs

- website bucket name
- CloudFront distribution id

Used by the frontend build and deploy workflow path.

The Terraform module uploads a bootstrap `index.html` so the distribution serves a valid page before the built frontend assets are published. Later frontend deploys replace that object with the real app bundle output.
