# `lambda_worker`

Lambda worker that consumes the shared worker SQS queue.

## What It Does

- receives messages from the Lambda worker queue
- processes SQS records in small chunks
- returns partial batch failures so only failed records are retried
- logs each processed message through the shared JSON logger

## Message Source

Production flow:

```text
Lambda API -> SNS worker topic -> Lambda worker SQS queue -> lambda_worker
```

The same SNS topic also fans out to the ECS worker queue.

## Local Publishing

Start the local stack:

```sh
just start
```

Publish directly to this worker's local queue:

```sh
just local-sqs-send lambda-worker-queue
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

## Local Runtime

- Compose runs the worker through `local/invoke_harness.py`
- local SQS is backed by ElasticMQ
- the queue URL is passed with `AWS_SQS_QUEUE_URL`
- `watchfiles` restarts the worker when Python files change

## Related Docs

- Lambda source layout: [../README.md](../README.md)
- Lambda API publish contract: [../lambda_api/README.md](../lambda_api/README.md)
- Worker infra module: [../../infra/modules/aws/lambda_worker/README.md](../../infra/modules/aws/lambda_worker/README.md)
