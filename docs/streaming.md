# Streaming

Ordo supports streaming delivery for inference tasks via SSE.

## STREAM Mode Overview
- Submit with `mode=STREAM`
- Ordo creates a stream session per task_id
- Client subscribes to:
  - `GET /v1/executions/{task_id}/stream`
- Executors may emit stream events (delta/log/progress)
- Ordo emits a final event with outputs/error

## Guarantees (v0.1)
- Best-effort delivery
- One consumer per task stream
- No replay, no reconnect resume

## Event Types
- `delta`: partial output (e.g., tokens)
- `log`: structured messages
- `progress`: stage progress
- `final`: final result including outputs/error

## SSE Format
```text
event: delta
data: {...}

event: final
data: {...}