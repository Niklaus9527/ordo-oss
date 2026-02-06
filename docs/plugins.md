# 🔌 Plugins (Development Guide)

Ordo keeps the core small and extends functionality through plugins.
v0.1 includes:
- executor plugins (HTTP/local)
- output plugin (SSE)

This guide defines plugin interfaces, configuration, and development conventions.

---

## 1) Plugin Philosophy

- **Core** defines contracts and invariants:
  - workflow spec
  - scheduler semantics
  - execution model
  - engine call conventions

- **Plugins** implement behaviors:
  - how a stage is executed
  - how artifacts are stored
  - how streams are delivered
  - how observability exports data

Plugins should be:
- replaceable
- testable (unit + e2e)
- configured declaratively

---

## 2) Executor Plugin

### 2.1 Interface (v0.1)

Executor implementations must satisfy:

```go
type Executor interface {
  Execute(ctx context.Context, req ExecRequest) (ExecResponse, error)
}
```

# 🔌 Plugins (Development Guide)

Ordo keeps the core small and extends functionality through plugins.
v0.1 includes:
- executor plugins (HTTP/local)
- output plugin (SSE)

This guide defines plugin interfaces, configuration, and development conventions.

---

## 1) Plugin Philosophy

- **Core** defines contracts and invariants:
  - workflow spec
  - scheduler semantics
  - execution model
  - engine call conventions

- **Plugins** implement behaviors:
  - how a stage is executed
  - how artifacts are stored
  - how streams are delivered
  - how observability exports data

Plugins should be:
- replaceable
- testable (unit + e2e)
- configured declaratively

---

## 2) Executor Plugin

### 2.1 Interface (v0.1)

Executor implementations must satisfy:

```go
type Executor interface {
  Execute(ctx context.Context, req ExecRequest) (ExecResponse, error)
}
```

Where:

- `ExecRequest` contains task/workflow/version/deployment/stage and resolved inputs.
- `ExecResponse` returns:
  - `artifacts: map[string]ArtifactRef`
  - `metadata: map[string]any`

### 2.2 Logical executor names

Workflow stages reference executors using **logical names**:

```
stages:
  - id: chat
    executor: mock.llm.http
```

These logical names are mapped to implementations in `providers.yaml`.

------

## 3) Providers Mapping (v0.1)

`providers.yaml` maps logical executor → type + config:

```
executors:
  mock.llm.http:
    type: http
    endpoint: http://localhost:18080/v1/mock/llm

  i23d.preprocess.local:
    type: local
    behavior: preprocess
```

Supported types in v0.1:

- `http`
- `local`

------

## 4) HTTP Executor (v0.1)

The HTTP executor sends a JSON payload:

```
{
  "task_id": "...",
  "workflow_id": "...",
  "version": "...",
  "deployment_id": "...",
  "stage_id": "...",
  "input": {
    "params": {...},
    "artifacts": {...}
  }
}
```

And expects:

```
{
  "artifacts": {"glb": {"uri":"s3://...","content_type":"model/gltf-binary"}},
  "metadata": {"vertices":12345}
}
```

Conventions:

- the remote service should be idempotent if retries are enabled (v0.2+)
- errors should be returned as non-2xx

------

## 5) Local Executor (v0.1)

Local executor is for demo/testing and supports simple behaviors:

- `preprocess`
- `geometry`
- `texture`
- `convert`
- `sleep:<ms>` (E2E helper)

Local executor returns `mock://...` URIs by default.

------

## 6) Output Plugin: SSE (v0.1)

SSE output is a minimal progress channel:

- subscribe via `GET /v1/executions/{task_id}/stream`
- engine emits lifecycle events into an in-memory hub

Events:

- `start`, `stage_start`, `stage_success`, `stage_fail`, `final`, `end`

Future:

- token-level streaming standard contract for LLM executors

------

## 7) Versioning & Compatibility

- Workflow spec versions are user-facing (`metadata.version`)
- Plugin compatibility is managed by Ordo core versioning.
- v0.1 does not provide a formal plugin ABI; plugins are built in-tree.

Recommended conventions:

- keep plugin configs backward compatible
- add new fields without breaking existing ones

------

## 8) Testing Plugins

Recommended tests:

- unit tests for input mapping and error handling
- e2e tests with hermetic server:
  - HTTP executor: `httptest.NewServer`
  - local executor: known behaviors

See `tests/e2e/`.