# `worker`

ECS worker that consumes the shared ECS worker SQS queue.

## What It Does

- polls SQS for worker messages
- continues async traces from Lambda/SNS/SQS message attributes
- persists processed messages to PostgreSQL
- writes a heartbeat file used by the container health check
- logs structured processing events to stdout

## Message Source

Production flow:

```text
Lambda API -> SNS worker topic -> ECS worker SQS queue -> containers/worker
```

The same SNS topic also fans out to the Lambda worker queue.

## Local Publishing

Start the local stack:

```sh
just start
```

Publish directly to this worker's local queue:

```sh
just local-sqs-send ecs-worker-queue
```

Publish to both local worker queues:

```sh
just local-worker-publish
```

Publish through the local Lambda API:

```sh
curl -X POST \
  -H 'Content-Type: application/json' \
  -d '{"job_id":"local-demo","source":"api","payload":{"hello":"world"}}' \
  http://localhost:18080/messages
```

## Production Publishing

Publish through the deployed Lambda API:

```sh
curl -X POST \
  -H 'Content-Type: application/json' \
  -d '{"job_id":"demo-1","source":"api","payload":{"hello":"world"}}' \
  https://<your-domain>/api/messages
```

Or publish directly to the shared worker SNS topic:

```sh
TOPIC_ARN=arn:aws:sns:eu-west-2:123456789012:aws-serverless-github-deploy-dev-worker-events \
MESSAGE='{"job_id":"demo-1","source":"local","payload":{"hello":"world"}}' \
just sns-publish
```

## Local Verification

Print persisted worker messages:

```sh
just messages
```

The local worker records:

- `job_id`
- `message_type`
- `correlation_id`
- `source_queue`
- `processed_at`

## Debug Shells

Open a local database shell through the debug container:

```sh
just debug
psql -v ON_ERROR_STOP=1 -c '\dt'
```

Open an ECS worker debug shell in AWS:

```sh
just worker-debug-shell dev
```

The shared debug image includes `psql`.
`worker-debug-shell` injects `PGPASSWORD`, `PGUSER`, and `DB_USER` from the shared database credentials secret before opening ECS Exec.

## Local Runtime

- Compose runs `containers/worker/app.py` under `watchfiles`
- local SQS is backed by ElasticMQ
- local PostgreSQL stores processed worker messages
- the queue URL is passed with `AWS_SQS_QUEUE_URL`
- `AWS_ENDPOINT_URL_SQS` points boto3 at ElasticMQ locally
- dummy AWS credentials are supplied for local SQS request signing

## Related Docs

- Container source layout: [../README.md](../README.md)
- Lambda API publish contract: [../../lambdas/lambda_api/README.md](../../lambdas/lambda_api/README.md)
- Worker task module: [../../infra/modules/aws/task_worker/README.md](../../infra/modules/aws/task_worker/README.md)
- Worker service module: [../../infra/modules/aws/service_worker/README.md](../../infra/modules/aws/service_worker/README.md)
