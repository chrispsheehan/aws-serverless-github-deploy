# `frontend`

Static frontend hosting module.

## Owns

- website bucket and distribution resources
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
