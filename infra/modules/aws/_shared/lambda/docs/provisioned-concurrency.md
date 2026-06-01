# Lambda Provisioned Concurrency

Use `provisioned_config` to choose the Lambda warm-capacity shape.

## No Provisioned Concurrency

- best for background jobs and lower-frequency work where cold-start lag is acceptable

```hcl
provisioned_config = {
  fixed                = 0
  reserved_concurrency = 2
}
```

## Fixed Provisioned Concurrency

- best for predictable request volume where you want a known warm pool

```hcl
provisioned_config = {
  fixed                = 10
  reserved_concurrency = 50
}
```

## Autoscaled Provisioned Concurrency

- best for request-serving Lambdas where you want baseline warm capacity and cost control above that baseline

```hcl
provisioned_config = {
  auto_scale = {
    max               = 3
    min               = 1
    trigger_percent   = 70
    cool_down_seconds = 60
  }
}
```
