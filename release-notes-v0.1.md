# 🏷️ Release Notes — v0.1

Ordo v0.1 is the first OSS milestone of an application-side multimodal inference hub.
It focuses on:
- workflow-driven inference orchestration
- multi-deployment routing (multi-cloud ready)
- bounded queue admission control
- observability and streaming events
- a runnable local demo + hermetic E2E tests

---

## ✨ Highlights

- ✅ Workflow registry with versions (`workflow_id@version`)
- ✅ Execution API (SYNC / ASYNC / STREAM)
- ✅ Scheduler with:
  - multi-deployment routing (labels + failover)
  - atomic admission (no oversubscription)
  - bounded queue (B+)
- ✅ Engine:
  - DAG topo execution (sequential)
  - stage IO resolver + output mapping
- ✅ SSE stream for lifecycle/progress events
- ✅ Prometheus metrics for capacity, queue, latency, success rate
- ✅ Hermetic E2E tests + CI

---

## 🔌 Included Plugins

- ✅ HTTP executor plugin (`type: http`)
- ✅ Local executor plugin (`type: local`) for demo/testing
- ✅ SSE output plugin for streaming events

---

## 📦 API Summary

### Submit
- `POST /v1/executions`
  - modes: `SYNC | ASYNC | STREAM`

### Inspect
- `GET /v1/executions/{task_id}`

### Stream
- `GET /v1/executions/{task_id}/stream` (SSE)

### Capacity
- `GET /v1/workflows/{workflow_id}/capacity?version=...`

---

## ✅ v0.1 Release Gates (Must Pass)

### 🧪 Tests
- [ ] `make test` passes
- [ ] `make e2e` passes (hermetic)

### 🧱 Build
- [ ] `go build ./cmd/ordo` passes

### 🧩 Demo
- [ ] `docs/demo.md` steps runnable end-to-end
- [ ] SYNC demo works (llm.chat)
- [ ] ASYNC demo works (pipeline)
- [ ] STREAM demo works (SSE events)
- [ ] Bounded queue demo shows 409 on overload

### 📈 Observability
- [ ] `/metrics` enabled and returns:
  - `ordo_http_requests_total`
  - `ordo_scheduler_inflight`
  - `ordo_scheduler_queue_depth`
  - `ordo_execution_total`
- [ ] `docs/observability.md` includes PromQL examples

### 📚 Docs
- [ ] README (EN) quickstart is copy/paste runnable
- [ ] README (CN) quickstart is copy/paste runnable
- [ ] `docs/faq.md` covers capacity / versions / multi-deploy / streaming

---

## ⚠️ Known Limitations (v0.1)

- In-memory execution store and queues:
  - restart loses inflight/queued state
- DAG execution is sequential (no parallel stage execution)
- SSE is lifecycle/progress events; token-level streaming is not standardized yet
- Weighted routing is best-effort (deterministic pick) rather than strict distribution

---

## 🔜 Next (v0.2 Preview)

- Persistent execution store (Postgres/SQLite)
- Persistent queue (Redis/NATS)
- standardized token streaming for executors
- strict weighted routing + health-aware deployments