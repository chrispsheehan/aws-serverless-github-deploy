# `frontend`

React frontend built with Vite.

## Commands

Run only the frontend dev server:

```sh
just frontend
```

Build the production bundle:

```sh
npm --prefix frontend run build
```

Preview a built bundle:

```sh
npm --prefix frontend run preview
```

## Local Development

- `just start` also starts the Vite dev server on `http://localhost:5173`
- the frontend runs outside Docker
- Vite proxies `/api/*` to the local Lambda API at `http://localhost:18080`
- Vite proxies `/api/ecs/*` to the local ECS API at `http://localhost:18081`
- `LOCAL_LAMBDA_API_URL` and `LOCAL_ECS_API_URL` can override those local targets
- `auth-config.json` is served with no-cache headers during local development

## Auth

Local auth config lives at:

```text
frontend/public/auth-config.json
```

When `"enabled": false`, the frontend runs locally without redirecting to Cognito.

The deployed app uses Cognito Hosted UI with the authorization-code-plus-PKCE flow.

The Cognito stack creates the user pool, app client, Hosted UI domain, and `readonly` group.
It does not create users automatically. To seed the initial read-only user after `cognito` is applied:

```sh
just cognito-create-readonly-user dev readonly@example.com 'ChangeMe123!'
```

The frontend and Cognito stacks read `domain_name` from the shared Terragrunt global inputs in [infra/live/global_vars.hcl](../infra/live/global_vars.hcl).
That keeps the deployed domain and auth callback/logout URLs consistent without extra CI wiring.

Detailed auth and hosting contracts:

- [infra/modules/aws/cognito/README.md](../infra/modules/aws/cognito/README.md)
- [infra/modules/aws/frontend/README.md](../infra/modules/aws/frontend/README.md)

## API Publish Path

The example frontend publishes browser telemetry through the Lambda API:

```text
POST /api/messages
```

The local Vite proxy rewrites that to the local Lambda API route:

```text
POST http://localhost:18080/messages
```

That API publishes to the shared worker fanout path.

More detail:

- API contract: [lambdas/lambda_api/README.md](../lambdas/lambda_api/README.md)
- Lambda worker consumer: [lambdas/lambda_worker/README.md](../lambdas/lambda_worker/README.md)
- ECS worker consumer: [containers/worker/README.md](../containers/worker/README.md)
