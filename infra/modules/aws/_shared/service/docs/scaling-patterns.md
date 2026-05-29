# ECS Scaling Patterns

Use `desired_task_count` as the steady-state baseline and `scaling_strategy` when you want autoscaling above that baseline.

## Fixed Task Count

- use for predictable or low-volume services where a fixed number of tasks is enough
- leave `scaling_strategy = {}`

```hcl
desired_task_count = 1

scaling_strategy = {}
```

## CPU Scaling

- use when task CPU is the best leading signal for scale pressure
- best fit for internal workers or APIs whose load correlates with compute saturation

```hcl
desired_task_count = 1

scaling_strategy = {
  max_scaled_task_count = 4
  cpu = {
    scale_out_threshold  = 70
    scale_in_threshold   = 30
    scale_out_adjustment = 1
    scale_in_adjustment  = -1
    cooldown_out         = 120
    cooldown_in          = 300
  }
}
```

## SQS Scaling

- use for queue-driven workers
- scale decisions are based on the named queue's visible-message count

```hcl
desired_task_count = 1

scaling_strategy = {
  max_scaled_task_count = 6
  sqs = {
    queue_name           = "my-worker-queue"
    scale_out_threshold  = 10
    scale_in_threshold   = 0
    scale_out_adjustment = 1
    scale_in_adjustment  = -1
    cooldown_out         = 60
    cooldown_in          = 300
  }
}
```

## ALB Request Scaling

- use for load-balanced HTTP services
- scale decisions are based on target requests per task behind the ALB

```hcl
desired_task_count = 2

scaling_strategy = {
  max_scaled_task_count = 6
  alb = {
    target_requests_per_task = 100
    cooldown_out             = 60
    cooldown_in              = 300
  }
}
```
