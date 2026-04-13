# `frontend`

Static frontend hosting module.

## Owns

- website bucket and distribution resources
- bootstrap `index.html` object for first-time infra deploys
- deployment destination for built frontend assets
- path-based forwarding of `/api/*` requests to the shared API origin

## Routing behavior

- `/api/*`
  forwarded to API Gateway and stripped to `/*` for the Lambda-backed API
- `/api/ecs/*`
  forwarded to API Gateway and stripped to `/ecs/*`
- all other paths
  served from the frontend bucket with SPA routing

## Key outputs

- website bucket name
- CloudFront distribution id

Used by the frontend build and deploy workflow path.

The Terraform module uploads a bootstrap `index.html` so the distribution serves a valid page before the built frontend assets are published. Later frontend deploys replace that object with the real app bundle output.
