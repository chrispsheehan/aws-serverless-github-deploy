# `containers/api`

HTTP ECS API service used by the sample `service_api` stack.

## Routes

- `GET /health`
- `GET /egress`
- `GET /fail`
- `GET /error`
- `GET /`

`GET /egress` calls the public URL in `EGRESS_CHECK_URL`, defaulting to `https://api.ipify.org?format=json`, and returns the public IP observed by that third-party service.
Use it after deploying `service_api` to prove that the running task has direct public internet egress.

Through the frontend/API Gateway path, call:

```sh
curl \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "$FRONTEND_OR_API_BASE_URL/api/ecs/egress"
```

The deployed route is protected by the shared Cognito JWT authorizer. Calling it from a browser address bar or with curl without the `Authorization` header returns `401 Unauthorized` before the request reaches the ECS task.

A successful response means the container reached the public internet from inside the ECS task. A `502` response means the task could not complete the outbound public egress check.
This proves runtime public egress. In an environment with NAT, a private task could also pass this check, so use it alongside the Terraform service network configuration when proving public-subnet placement specifically.
