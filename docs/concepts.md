# 🧠 Concepts (for users)

This document explains Ordo concepts for external users.

---

## 1) Workflow

A **workflow** is a versioned DAG describing how to execute a task.

- ID: `workflow_id` (e.g. `i23d.pipeline`)
- Version: `v2.0`
- Stages: ordered by dependencies (DAG)
- Outputs: a mapping that defines what the final result contains

A workflow version is immutable in principle; publish new versions for changes.

---

## 2) Stage

A **stage** is a single step in a workflow, executed by an **executor**.

Each stage defines:
- `executor`: logical executor name (e.g. `mock.llm.http`)
- `dependsOn`: upstream stages
- `input`:
  - `params.fromInputs`: keys copied from the submit request `inputs`
  - `artifacts.fromStage`: artifacts copied from other stages
- `output`: declared artifacts/metadata produced by this stage

Stages can represent:
- CPU preprocessing
- GPU inference service call
- external API call (OpenAI/DeepSeek/Kimi)
- format conversion + upload
- post-processing + validation

---

## 3) Inputs, Artifacts, Outputs

### Inputs (request-scoped parameters)
When submitting an execution, the caller provides:
```json
{
  "inputs": {
    "images": ["http://..."],
    "quality": "high",
    "target_format": "glb",
    "variant": "geom_texture"
  }
}
```

# 🧠 Concepts (for users)

This document explains Ordo concepts for external users.

---

## 1) Workflow

A **workflow** is a versioned DAG describing how to execute a task.

- ID: `workflow_id` (e.g. `i23d.pipeline`)
- Version: `v2.0`
- Stages: ordered by dependencies (DAG)
- Outputs: a mapping that defines what the final result contains

A workflow version is immutable in principle; publish new versions for changes.

---

## 2) Stage

A **stage** is a single step in a workflow, executed by an **executor**.

Each stage defines:
- `executor`: logical executor name (e.g. `mock.llm.http`)
- `dependsOn`: upstream stages
- `input`:
  - `params.fromInputs`: keys copied from the submit request `inputs`
  - `artifacts.fromStage`: artifacts copied from other stages
- `output`: declared artifacts/metadata produced by this stage

Stages can represent:
- CPU preprocessing
- GPU inference service call
- external API call (OpenAI/DeepSeek/Kimi)
- format conversion + upload
- post-processing + validation

---

## 3) Inputs, Artifacts, Outputs

### Inputs (request-scoped parameters)
When submitting an execution, the caller provides:
```json
{
  "inputs": {
    "images": ["http://..."],
    "quality": "high",
    "target_format": "glb",
    "variant": "geom_texture"
  }
}
```

### Artifacts (large objects by reference)

Artifacts are not embedded; they are passed by reference:

- `s3://bucket/key`
- `oss://bucket/key`
- `https://...`
- `mock://...` (demo/testing)

### Outputs (final contract)

Workflow `spec.outputs` maps:

- final artifacts from some stage artifact
- final metadata from some stage metadata key

This makes the final API response stable even if internal stage wiring changes.

------

## 4) Deployment

A **deployment** is a runtime target for the same workflow version.

Example: workflow version `v2.0` deployed on:

- `v2.0-volc` (Volcengine GPUs)
- `v2.0-tx` (Tencent GPUs)

Each deployment has:

- labels (for routing): `cloud`, `pool`, `region`, etc.
- capacity:
  - `slots`: max concurrent inflight
  - `queueSize`: max waiting queue depth

------

## 5) Routing Policy

Routing policy decides which deployment runs a task.

Typical use cases:

- multi-cloud capacity pooling
- gray release / canary (weights)
- variant pools (geom-only vs texture-heavy)
- sticky routing (consistent assignment per user)

v0.1 supports:

- label-based rules and a deterministic choice
- failover on `NO_CAPACITY` / `QUEUE_FULL`

------

## 6) Scheduler (capacity-aware admission)

Ordo uses B+ bounded admission per deployment:

- If `inflight < slots` → **accepted** (runs now)
- Else if `queueDepth < queueSize` → **queued** (runs later)
- Else → **rejected** (HTTP 409)

Even if callers do capacity checks, Ordo still enforces admission to avoid oversubscription.

------

## 7) Execution

An **execution** is a single run of a workflow version:

- identified by `task_id`
- contains stage states and outputs
- can be inspected via:
  - `GET /v1/executions/{task_id}`

Execution modes:

- SYNC: wait and return final result
- ASYNC: return `task_id`, poll or callback
- STREAM: return `task_id`, subscribe to SSE events

------

## 8) Streaming (SSE)

Ordo v0.1 provides SSE events for lifecycle/progress:

- `start`
- `stage_start`
- `stage_success`
- `stage_fail`
- `final`
- `end`

Token-level streaming for LLMs is implemented by executors emitting partial outputs into the SSE hub (planned as a standardized contract in future versions).

------

## 9) Plugins vs Integrations

- **Plugins**: implementations of Ordo extension points
  - executors, artifact store, observability, output stream, etc.
- **Integrations**: production connectors
  - Kubernetes, cloud auth/IAM, Kafka, object stores, etc.

Ordo core defines the contracts; plugins and integrations implement them.