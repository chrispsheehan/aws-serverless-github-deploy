# `cognito`

Concrete Cognito user-auth module for the frontend and HTTP API.

## Owns

- Cognito user pool
- frontend SPA user-pool client using OAuth authorization code flow with PKCE
- Cognito Hosted UI domain
- read-only user group

## Inputs

- `callback_urls`
- `logout_urls`
- optional token lifetime settings
- optional `readonly_group_name`

## Key outputs

- `user_pool_id`
- `user_pool_arn`
- `user_pool_client_id`
- `issuer_url`
- `hosted_ui_url`
- `hosted_ui_domain`
- `readonly_group_name`

This module intentionally creates infrastructure, not individual users. In this repo, user seeding is expected to happen operationally with AWS CLI or `just` recipes so access can be granted explicitly to a small allowlist such as the initial `readonly` user.
