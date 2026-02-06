# 🧩 Contributing to Ordo

Thanks for your interest in contributing to Ordo! This guide explains how to propose changes, run tests, and submit pull requests.

---

## ✅ Ways to Contribute

- Report bugs / request features (GitHub Issues)
- Improve docs and examples
- Add executor plugins (HTTP integrations, local demos)
- Add integrations (Kubernetes, auth, queue backends)
- Improve observability (metrics, tracing)
- Improve tests (unit, E2E)

---

## 🛠️ Development Setup

### Requirements
- Go 1.22+
- (Optional) Docker (for `examples/mock-server`)

### Build & test

```bash
make tidy
make fmt
make lint
make test
make e2e
make build
```

------

## 🧪 Running locally

```
go run ./cmd/ordo --config configs/ordo.example.yaml
```

Health:

```
curl -s http://localhost:8080/healthz
```

------

## 📦 Project Conventions

### Code style

- Run `gofmt` on all Go files
- Keep public interfaces small and documented
- Prefer adding fields over breaking changes

### API rules (v0.1)

- Submit API: `POST /v1/executions`
  - modes: `SYNC | ASYNC | STREAM`
- Inspect: `GET /v1/executions/{task_id}`
- Stream: `GET /v1/executions/{task_id}/stream` (SSE)
- Capacity: `GET /v1/workflows/{id}/capacity?version=...`

### Workflow compatibility

- Treat `workflow_id@version` as immutable
- Publish new versions instead of mutating existing ones

### Plugins

- Keep plugin implementations replaceable and testable
- Use `providers.yaml` mapping for executor logical names

------

## ✅ Pull Request Checklist

Before opening a PR:

-  `make test` passes
-  `make e2e` passes
-  docs updated (if behavior changes)
-  add/update examples if applicable
-  follow backward-compatible changes unless it’s a major version bump

------

## 🧯 Reporting Security Issues

Please do not open public issues for security-sensitive problems.

Instead, contact maintainers privately (or use your organization’s standard security reporting channel).