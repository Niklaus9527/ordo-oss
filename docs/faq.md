# ❓ FAQ (v0.1)

This FAQ focuses on Ordo as an **application-side multimodal inference hub**:
- manage internal models and external model APIs
- orchestrate multimodal workflows
- capacity-aware scheduling (multi-deployment + bounded queue)
- observability and streaming events

---

## 🧠 Concepts

### 1) What is Ordo?
Ordo is a workflow-driven inference hub for multimodal applications. It provides:
- Workflow registry (YAML)
- Execution API (submit/get/stream)
- Scheduler (multi-deployment routing + bounded queue)
- Pluggable executors (HTTP/local) and future integrations

### 2) Is Ordo a model serving system?
Not directly. Ordo is the **orchestrator**. Model serving can be:
- external APIs (OpenAI/DeepSeek/Kimi/etc.)
- internal services (HTTP/gRPC)
- local executors (dev/demo)

---

## 🧩 Workflows & Versions

### 3) Is “one workflow = one model”?
Not necessarily.
- A workflow is a **pipeline** that may call one or many models/services.
- A single “3D model version” can be modeled as one workflow version.

### 4) How do you represent v2.0-volc vs v2.0-tx?
Use **deployments** under the same `(workflow_id, version)`:
- `deployment_id: v2.0-volc`
- `deployment_id: v2.0-tx`
Routing rules distribute traffic based on labels/weights (multi-cloud).

### 5) How do you support gray release / canary?
Use routing weights:
- 95% → `v2.0-volc`
- 5%  → `v2.0-tx`
Then gradually increase.

> v0.1 uses deterministic selection with optional failover; strict weighted distribution is a planned enhancement.

---

## 🧵 Stage IO / Artifacts

### 6) Where are stage inputs/outputs defined?
In workflow YAML:
- `stage.input.params.fromInputs` picks keys from initial request `inputs`
- `stage.input.artifacts.fromStage` references artifacts produced by previous stages
- `spec.outputs` maps final outputs from stage artifacts/metadata

### 7) How to represent “business parameters” (resolution, file urls, output types)?
Put them into `inputs`:
```json
{
  "inputs": {
    "model_version":"v2.0",
    "resolution":"1024",
    "images":["http://..."],
    "target_format":"glb"
  }
}
```

The workflow controls how each stage consumes them.

### 8) How are intermediate artifacts managed?

v0.1 treats artifacts as references (`ArtifactRef{uri,...}`).

- local demo can use `mock://...`
- production should use object storage URIs (S3/OSS/COS/GCS)

------

## 🧮 Scheduling & Capacity

### 9) How does Ordo solve “manual deployment & manual resource allocation”?

Ordo separates concerns:

- deployments define **capacity** (`slots`, `queueSize`)
- scheduler performs **atomic admission**
- queued tasks run when a worker releases inflight

This replaces manual “human decides where to run” with deterministic scheduling.

### 10) What is “B+ bounded queue” behavior?

For a deployment:

- `slots=N`: max concurrent inflight tasks
- `queueSize=M`: max pending tasks waiting in queue
   When `inflight==N`:
- if queue has room: request is accepted as queued
- else: reject with `409` (no capacity)

### 11) Should callers check capacity before submit?

Yes, recommended:

- call `GET /v1/workflows/{id}/capacity?version=...`
- decide whether to submit

But Ordo still enforces admission to prevent oversubscription.

### 12) How to avoid resource contention between “geom-only” and “geom+texture”?

Use **variant pools**:

- set `inputs.variant = geom_only | geom_texture | texture_only`
- route to deployments labeled `pool: geom_only` etc.
   This isolates heavy tasks from starving lighter tasks.

------

## 🌊 Streaming

### 13) How does Ordo support DeepSeek-style token streaming?

v0.1 provides SSE event channel for progress + lifecycle events.
 Token-level streaming is achieved by:

- executor/plugin emits partial tokens to SSE hub
- Ordo exposes the same SSE stream to clients

This is planned as a v0.2+ executor feature (standardized streaming callbacks).

------

## 🛡️ Reliability / SLA

### 14) How does Ordo ensure SLA?

v0.1 baseline:

- bounded queue protects system from overload
- per-stage timeout field exists in workflow spec
- observability metrics enable alerting

Production hardening (future):

- persistence for execution state
- retries with idempotency keys
- circuit breakers for external APIs

### 15) Can Ordo do smooth upgrade / restart?

In production, run Ordo stateless with:

- external persistence (DB/Redis) for executions and queues
- rolling update via Kubernetes

v0.1 uses in-memory state; restarting loses inflight/queue states (expected for OSS demo).

------

## 🔌 Plugins & Integrations

### 16) What is a “core” vs “plugin” vs “integration”?

- **Core**: workflow/execution/scheduler/engine APIs & invariants
- **Plugins**: executors, artifact store, observability exporters
- **Integrations**: Kubernetes, cloud IAM/auth, external queues (Kafka), object stores

------

## 🧱 Scope & Non-goals (v0.1)

### 17) Does Ordo replace Argo Workflows?

No. Argo is a general Kubernetes workflow engine.
 Ordo is application-side inference orchestration with:

- inference-centric IO abstraction
- multi-deployment routing (multi-cloud)
- capacity admission semantics

Ordo can integrate Argo as a workflow executor plugin in the future.

### 18) Does Ordo replace Dify?

No. Dify is an app builder for LLM apps.
 Ordo focuses on workflow execution + scheduling + capacity + multimodal pipelines, and can be used under a UI layer like Dify.