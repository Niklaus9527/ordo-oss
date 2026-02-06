# Observability

Ordo v0.1 ships with first-class observability for an application-side multimodal inference hub:
- **Metrics (Prometheus)**: capacity, queues, inflight, latency, success rate
- **Execution inspection**: `GET /v1/executions/{task_id}`
- **Streaming events (SSE)**: `GET /v1/executions/{task_id}/stream`

This document explains how to enable metrics, what each metric means, and recommended dashboards (PromQL).

---

## Enable Prometheus Metrics

In `configs/ordo.example.yaml`:

```yaml
observability:
  prometheus:
    enabled: true
    path: /metrics
```

Start Ordo:

```bash
ordo server --config configs/ordo.example.yaml
```

Scrape endpoint:

- `GET http://<ordo-host>:8080/metrics`

------

## Metric Catalog (v0.1)

### HTTP layer

- `ordo_http_requests_total{method,path,status}`
  - Total HTTP requests
- `ordo_http_request_duration_ms_bucket{method,path,le}`
  - HTTP request duration histogram in milliseconds

### Scheduler layer

- `ordo_scheduler_admit_total{workflow,version,decision,deployment}`
  - Scheduler decisions
  - `decision`: `accepted|queued|rejected`
- `ordo_scheduler_reject_total{workflow,version,reason}`
  - Rejection reasons
  - `reason`: `NO_CAPACITY|QUEUE_FULL`
- `ordo_scheduler_inflight{workflow,version,deployment}`
  - Current inflight count per deployment (Gauge)
- `ordo_scheduler_queue_depth{workflow,version,deployment}`
  - Current queue depth per deployment (Gauge)

### Engine / Execution layer

- `ordo_execution_total{workflow,version,status}`
  - Execution terminal outcomes
  - `status`: `succeeded|failed`
- `ordo_stage_total{workflow,version,stage,status}`
  - Stage terminal outcomes
- `ordo_stage_duration_ms_bucket{workflow,version,stage,le}`
  - Stage duration histogram in ms
- `ordo_execution_latency_ms_bucket{workflow,version,le}`
  - End-to-end execution latency histogram in ms

### Delivery layer (optional in v0.1)

- `ordo_delivery_callback_total{type,status}`
  - Callback deliveries
  - `type`: `http|stdout`
  - `status`: `success|fail`

------

## Recommended Dashboards (PromQL)

> Tip: you can build a usable dashboard with 6 panels.

### 1) Total inflight (cluster utilization)

```promql
sum(ordo_scheduler_inflight)
```

### 2) Queue depth by deployment (hotspots)

```promql
ordo_scheduler_queue_depth{workflow="i23d.pipeline",version="v2.0"}
```

### 3) Success rate (5m rolling)

```promql
sum(rate(ordo_execution_total{status="succeeded"}[5m]))
/
sum(rate(ordo_execution_total[5m]))
```

### 4) Execution P95 latency (by workflow)

```promql
histogram_quantile(
  0.95,
  sum(rate(ordo_execution_latency_ms_bucket[5m])) by (le, workflow, version)
)
```

### 5) Stage P95 latency (find bottlenecks)

```promql
histogram_quantile(
  0.95,
  sum(rate(ordo_stage_duration_ms_bucket[5m])) by (le, stage, workflow, version)
)
```

### 6) HTTP P95 latency (API health)

```promql
histogram_quantile(
  0.95,
  sum(rate(ordo_http_request_duration_ms_bucket[5m])) by (le, path)
)
```

------

## Operational Playbook (v0.1)

### When users report “no capacity”

Check:

1. `ordo_scheduler_inflight` is near `slots`
2. `ordo_scheduler_queue_depth` is near `queueSize`
3. `ordo_scheduler_reject_total{reason="QUEUE_FULL"}` increases

Actions:

- Increase capacity (add deployments, increase slots)
- Split pools by variant (e.g. `geom_only` vs `geom_texture`) to isolate contention
- Add routing weights across multi-cloud deployments to spread load

### When latency increases

Check:

- Execution P95 panel
- Stage P95 panel to locate the slow stage
- If only one deployment is hot: queue depth panel will show skew

Actions:

- Increase slots on the hotspot deployment
- Adjust routing weights (multi-cloud)
- Apply variant pools to avoid “texture-heavy tasks” starving “geom-only tasks”

------

## Tracing / Logs (future)

v0.1 focuses on metrics and structured request/execution logs.
Future versions can add:

- OpenTelemetry traces
- centralized log export (Loki/ELK)
- per-stage structured logs with correlation IDs