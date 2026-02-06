- # 🗺️ ROADMAP

  This roadmap describes Ordo's evolution from **v0.1 demo** to a production-grade inference hub.

  ---

  ## ✅ v0.1 (MVP) — Current Target

  ### 🧱 Core
  - ✅ Workflow registry (YAML) with versions
  - ✅ Execution API
    - ✅ `POST /v1/executions` (SYNC/ASYNC/STREAM)
    - ✅ `GET /v1/executions/{task_id}`
    - ✅ `GET /v1/executions/{task_id}/stream` (SSE events)
  - ✅ Scheduler
    - ✅ multi-deployment routing (labels + failover)
    - ✅ atomic admission
    - ✅ bounded queue (B+)
    - ✅ capacity endpoint `GET /v1/workflows/{id}/capacity?version=...`
  - ✅ Engine
    - ✅ DAG topo execution (sequential)
    - ✅ input resolver (fromInputs/fromStage)
    - ✅ outputs mapping

  ### 🔌 Plugins
  - ✅ Executor: HTTP
  - ✅ Executor: Local (mock)
  - ✅ Output: SSE

  ### 📈 Observability
  - ✅ Prometheus metrics
  - ✅ E2E tests (hermetic)
  - ✅ CI gates

  ---

  ## 🚀 v0.2 (Production Foundations)

  ### 🧠 Execution durability
  - ⏳ Persistent execution store (Postgres / SQLite)
  - ⏳ Persistent queue (Redis / NATS JetStream)
  - ⏳ Idempotency keys + deduplication

  ### 🔁 Reliability
  - ⏳ Retry policies per stage (idempotent only)
  - ⏳ Circuit breaker for external APIs
  - ⏳ Deadline propagation & cancellation

  ### 🌊 Streaming
  - ⏳ Standard token streaming contract for executors
  - ⏳ Backpressure-aware SSE/WebSocket

  ---

  ## 🏗️ v0.3 (Multi-cloud & Ops)

  - ⏳ Strict weighted routing distribution
  - ⏳ Sticky routing TTL + eviction
  - ⏳ Health-aware routing (disable bad deployments)
  - ⏳ Autoscaling signals export (queue depth, inflight, latency)
  - ⏳ Dashboard templates (Grafana JSON)

  ---

  ## 🧩 v0.4 (Workflow UX & Ecosystem)

  - ⏳ Workflow SDK (typed inputs/outputs)
  - ⏳ Validation tooling & CLI
  - ⏳ Plugin registry / marketplace concept
  - ⏳ Argo / K8s workflow integration plugin

  ---

  ## 🏆 v1.0 (Stable API)

  - ⏳ Backward compatible workflow spec
  - ⏳ Stable plugin API with versioning
  - ⏳ Security hardening & governance maturity