# Ordo

**Ordo** is an application-side **multimodal inference hub**: a workflow-driven framework to orchestrate internal model services and external model APIs with **capacity-aware scheduling**, **multi-deployment routing**, and **observability**.

> Ordo is not a model-serving system by itself.  
> Ordo is the **orchestrator** that coordinates model endpoints/services as workflow stages.

---

## ✨ Why Ordo?

Modern AI applications rarely call a single model. They run **pipelines**:
- LLM → tool call → image generation → 3D reconstruction → post-processing
- internal GPU services + CPU stages + external APIs
- multiple model versions + multi-cloud deployments + gray release

Ordo provides a clean core with a plugin architecture so you can:
- manage workflows (DAG) with explicit stage IO contracts
- route traffic across **multiple deployments** for the same workflow version (multi-cloud)
- enforce **bounded queue admission** (B+ style) to protect SLA
- ship **SYNC / ASYNC / STREAM** execution modes for apps
- observe capacity, queues, inflight usage, latency, and success rate

---

## ✅ Features (v0.1)

### Workflow & Execution
- Workflow registry (YAML) with versions: `workflow_id@version`
- DAG execution (topological order, sequential in v0.1)
- Stage input resolver:
  - `fromInputs` (request inputs)
  - `fromStage` (artifacts from upstream stages)
- Output mapping: final outputs from stage artifacts/metadata

### Scheduling (Capacity-aware)
- Multi-deployment routing under the same `(workflow_id, version)`
- Atomic admission (no oversubscription)
- Bounded queue (B+ semantics): `slots` + `queueSize`
- Capacity API:
  - `GET /v1/workflows/{workflow_id}/capacity?version=...`

### Execution Modes
- **SYNC**: wait for terminal state (fast workflows)
- **ASYNC**: return `task_id` immediately + optional HTTP callback
- **STREAM**: SSE events (`start/stage/final`) over:
  - `GET /v1/executions/{task_id}/stream`

### Plugins (v0.1)
- Executor plugin: HTTP
- Executor plugin: Local (for demos/tests)
- Output plugin: SSE stream

### Observability
- Prometheus metrics: capacity/queue/latency/success rate
- Hermetic E2E tests (no docker required)

---

## 🚀 Quickstart

### 1) Run Ordo

```bash
go run ./cmd/ordo --config configs/ordo.example.yaml
```

Health:

```
curl -s http://localhost:8080/healthz
```

Metrics (if enabled):

```
curl -s http://localhost:8080/metrics | head
```

### 2) Capacity check

```
curl -s "http://localhost:8080/v1/workflows/i23d.pipeline/capacity?version=v2.0" | jq .
```

### 3) Submit (SYNC)

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

### 4) Submit (ASYNC)

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

curl -sS http://localhost:8080/v1/executions/$TASK | jq .
```

### 5) Submit (STREAM)

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

------

## 📚 Documentation

- 🧪 Demo: `docs/demo.md`
- ❓ FAQ: `docs/faq.md`
- 📈 Observability: `docs/observability.md`
- 🏗️ Architecture:
  - `docs/architecture.md`
  - `docs/concepts.md`
  - `docs/plugins.md`
  - `docs/integrations.md`
- 🗺️ Roadmap: `ROADMAP.md`
- 🏷️ Release Notes (v0.1): `release-notes-v0.1.md`

------

## 🧭 Architecture

### High-level system

```
flowchart TB
  Client[Client / App] -->|capacity check| OrdoAPI[Ordo API]
  Client -->|submit SYNC/ASYNC/STREAM| OrdoAPI

  subgraph Ordo[Ordo Core]
    OrdoAPI --> ExecSvc[Execution Service]
    OrdoAPI --> Sched[Scheduler]
    ExecSvc --> Store[Execution Store]
    Sched --> Route[Routing Policy]
    Sched --> Q[Bounded Queue]
    ExecSvc --> Engine[Engine]
    Engine --> Resolver[Input Resolver]
    Engine --> ExecMgr[Executor Manager]
    Engine --> Obs[Observability]
  end

  ExecMgr -->|HTTP| ExtAPI[External Model APIs]
  ExecMgr -->|HTTP| InternalSvc[Internal Model Services]
  ExecMgr -->|Local| LocalExec[Local Executors (Demo/Test)]

  OrdoAPI -->|SSE| Stream[Stream Output Plugin]
  Obs -->|/metrics| Prom[Prometheus]
```

### Key design points

- **Core** defines contracts: workflow spec, execution model, scheduler semantics, plugin interfaces
- **Plugins** provide implementations: executors, artifact store, observability exporters
- **Integrations** connect production systems: Kubernetes, cloud auth, queues, object stores

------

## ⏱️ Sequence Diagrams

### SYNC submit

```
sequenceDiagram
  participant C as Client
  participant A as Ordo API
  participant S as Scheduler
  participant E as Engine
  participant X as Executor

  C->>A: POST /v1/executions (mode=SYNC)
  A->>S: RouteAndAdmit()
  S-->>A: accepted (deployment)
  A->>E: Run(task_id)
  E->>X: Execute(stage1..n)
  X-->>E: outputs
  E-->>A: terminal status + outputs
  A-->>C: execution (SUCCEEDED/FAILED)
```

### ASYNC submit with bounded queue

```
sequenceDiagram
  participant C as Client
  participant A as Ordo API
  participant S as Scheduler
  participant E as Engine

  C->>A: POST /v1/executions (mode=ASYNC)
  A->>S: RouteAndAdmit()
  alt slots available
    S-->>A: accepted
    A-->>C: {task_id}
    A->>E: Run(task_id)
  else slots full, queue has room
    S-->>A: queued
    A-->>C: {task_id}
    Note over S: queued until release
  else queue full
    S-->>A: rejected (409)
    A-->>C: 409 NO_CAPACITY
  end
```

### STREAM (SSE)

```
sequenceDiagram
  participant C as Client
  participant A as Ordo API
  participant E as Engine
  participant SSE as SSE Hub

  C->>A: POST /v1/executions (mode=STREAM)
  A-->>C: {task_id}
  C->>A: GET /v1/executions/{task_id}/stream
  A->>SSE: subscribe
  E->>SSE: start/stage/final events
  SSE-->>C: SSE events
```

------

## 🔍 Relationship to Argo / Dify

### Argo Workflows

Argo is a general-purpose Kubernetes workflow engine. Ordo differs by focusing on **application-side inference semantics**:

- inference-centric IO contracts (params + artifacts)
- multi-deployment routing (multi-cloud) under one workflow version
- bounded queue admission for SLA protection
- app-friendly execution modes (SYNC/ASYNC/STREAM)

Ordo can integrate Argo as a workflow/executor plugin in the future.

### Dify

Dify is an app builder for LLM applications. Ordo is the execution/scheduling layer:

- Ordo can run under a UI layer like Dify
- Ordo provides routing/capacity/queues and multimodal pipelines for production

------

## 🔐 Ordo Inference (OSS) vs Internal

Ordo Inference (OSS) provides a stable **core** and plugin architecture.
 In a company environment, you can keep proprietary assets private:

- internal workflows (3D pipelines)
- internal executor plugins (GPU services)
- internal routing strategies or integrations

Ordo Inference (OSS) can ship only safe demos (e.g., `llm.chat`, `t2i.then.i23d`).

------

## 🧪 Testing

```
make test
make e2e
```

------

## 📄 License

See `LICENSE`.