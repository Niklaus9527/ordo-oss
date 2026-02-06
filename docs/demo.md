# 🧪 Demo (v0.1)

This demo shows how to run Ordo locally and try:
- ✅ Capacity check
- ✅ Submit executions in **SYNC / ASYNC / STREAM**
- ✅ Inspect execution status and outputs
- ✅ Bounded queue behavior (B+ queue)

> Notes:
> - Workflows and deployments are loaded from YAML under `configs/paths`.
> - Executors are mapped by `configs/providers.*.yaml` (logical name → http/local).
> - Example workflows include:
>   - `llm.chat@v1.0` (HTTP executor)
>   - `t2i.generate@v1.0` (HTTP executor) [optional if you have it]
>   - `i23d.pipeline@v2.0` (LOCAL executor mock)
>   - `t2i.then.i23d@v1.0` (pipeline)

---

## 0) Prerequisites

- Go 1.22+
- (Optional) Docker (only if you want to use `examples/mock-server`)

---

## 1) Run Ordo

### 1.1 Start mock-server (optional)

If your `providers.example.yaml` uses HTTP executors pointing to a mock server:

```bash
cd examples/mock-server
docker compose up --build -d
```

### 1.2 Start Ordo

```
go run ./cmd/ordo --config configs/ordo.example.yaml
```

Health check:

```
curl -s http://localhost:8080/healthz
```

Metrics (if enabled):

```
curl -s http://localhost:8080/metrics | head
```

------

## 2) Capacity Check

Query deployment utilization (slots / inflight / queue depth):

```
curl -s "http://localhost:8080/v1/workflows/i23d.pipeline/capacity?version=v2.0" | jq .
```

You should see:

- `slots`, `inflight`
- `queueSize`, `queueDepth`
- `availableSlots`

------

## 3) Submit Execution (SYNC)

Use SYNC for fast workflows.

```
curl -sS -X POST http://localhost:8080/v1/executions \
  -H "Content-Type: application/json" \
  -d '{
    "workflow_id":"llm.chat",
    "version":"v1.0",
    "mode":"SYNC",
    "inputs":{
      "provider":"mock",
      "model":"mock-chat",
      "messages":[{"role":"user","content":"hello"}]
    }
  }' | jq .
```

Expected:

- response is the **execution object**
- `status` is `SUCCEEDED` (or `FAILED` if executor errors)

------

## 4) Submit Execution (ASYNC)

Use ASYNC for slower workflows (e.g., 3D pipelines). Submit returns `task_id` immediately.

```
TASK=$(curl -sS -X POST http://localhost:8080/v1/executions \
  -H "Content-Type: application/json" \
  -d '{
    "workflow_id":"i23d.pipeline",
    "version":"v2.0",
    "mode":"ASYNC",
    "inputs":{
      "variant":"geom_texture",
      "images":["mock://a.png","mock://b.png"],
      "target_format":"glb"
    }
  }' | jq -r .task_id)

echo "task_id=$TASK"
```

Poll status:

```
curl -sS http://localhost:8080/v1/executions/$TASK | jq .
```

------

## 5) Submit Execution (ASYNC + HTTP callback)

Provide `callback_url` and Ordo will POST the result after terminal state.

```
curl -sS -X POST http://localhost:8080/v1/executions \
  -H "Content-Type: application/json" \
  -d '{
    "workflow_id":"i23d.pipeline",
    "version":"v2.0",
    "mode":"ASYNC",
    "callback_url":"http://your-callback-service/ordo/callback",
    "inputs":{
      "variant":"geom_only",
      "images":["mock://a.png"]
    }
  }' | jq .
```

Callback payload (example):

```
{
  "task_id":"...",
  "status":"SUCCEEDED",
  "workflow":"i23d.pipeline",
  "version":"v2.0",
  "deployment":"v2.0-volc",
  "outputs":{
    "artifacts":{"glb":{"uri":"s3://.../model.glb"}},
    "metadata":{"vertices":12345,"faces":67890}
  }
}
```

------

## 6) Submit Execution (STREAM via SSE)

STREAM returns `task_id`, then client subscribes to:

- `GET /v1/executions/{task_id}/stream`

```
TASK=$(curl -sS -X POST http://localhost:8080/v1/executions \
  -H "Content-Type: application/json" \
  -d '{
    "workflow_id":"llm.chat",
    "version":"v1.0",
    "mode":"STREAM",
    "inputs":{
      "provider":"mock",
      "model":"mock-chat",
      "messages":[{"role":"user","content":"stream please"}]
    }
  }' | jq -r .task_id)

curl -N http://localhost:8080/v1/executions/$TASK/stream
```

Typical events:

- `start`
- `stage_start`
- `stage_success`
- `final`
- `end`

> v0.1: SSE is used for progress/events; token-level streaming is a future enhancement.

------

## 7) Bounded Queue (B+)

If a deployment has `slots=1` and `queueSize=1`:

- 1 task inflight
- 1 task queued
- the 3rd concurrent submit is rejected with HTTP **409**

Try concurrently submitting 3 tasks (example pseudo):

```
for i in 1 2 3; do
  curl -s -o /dev/null -w "req$i status=%{http_code}\n" \
    -X POST http://localhost:8080/v1/executions \
    -H "Content-Type: application/json" \
    -d '{
      "workflow_id":"sleep.pipeline",
      "version":"v1.0",
      "mode":"ASYNC",
      "inputs":{"variant":"default"}
    }' &
done
wait
```

Expected:

- two requests → `200`
- one request → `409`

------

## 8) Inspect Executions

```
curl -sS http://localhost:8080/v1/executions/$TASK | jq .
```

Look for:

- `status`
- `stages[].status`
- `outputs.artifacts`
- `outputs.metadata`

------

## 9) Troubleshooting

- `workflow not found`:
  - check `configs/paths.workflowDir`
  - verify workflow YAML `metadata.id` and `metadata.version`
- `executor not found`:
  - check `configs/providers.*.yaml` has mapping for `stage.executor`
- `409 no capacity`:
  - check `GET /v1/workflows/{id}/capacity?version=...`
  - confirm `slots` and `queueSize`