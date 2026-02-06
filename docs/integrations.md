# 🔗 Integrations (v0.1 and beyond)

Integrations connect Ordo to production systems. v0.1 OSS keeps integrations minimal and demo-friendly, but the architecture is designed for gradual production hardening.

---

## 1) Kubernetes

### v0.1
- Ordo runs as a single process (stateless-ish, in-memory store/queue).
- Suitable for local demo and single-node deployments.

### Production (v0.2+)
To run Ordo safely in Kubernetes:
- externalize execution store (Postgres/SQLite)
- externalize queue backend (Redis/NATS)
- run Ordo as multiple replicas behind a Service
- implement leader election or sharded scheduling if needed

---

## 2) Cloud / Multi-cloud GPU Pools

Ordo supports multi-cloud at the **deployment** level:
- multiple deployments under the same workflow version
- routing policies distribute traffic

Best practices:
- label deployments by `cloud`, `region`, `pool`, `gpu_type`
- use variant pools to isolate heavy stages:
  - `geom_only`, `geom_texture`, `texture_only`
- start with failover + deterministic selection, then upgrade to strict weighted routing (future)

---

## 3) Object Storage (Artifacts)

v0.1 uses `ArtifactRef{uri}` and does not ship a built-in artifact store plugin.

Production options:
- S3-compatible
- OSS/COS
- GCS
- MinIO for self-host

Recommended approach:
- stage executors upload artifacts and return object storage URIs
- Ordo treats URIs as references and only maps them to outputs

Future extension:
- Artifact Store plugin (Ordo-managed upload + signed URL generation)

---

## 4) External Queues / Events (Kafka / HTTP callbacks)

v0.1 supports:
- HTTP callback via `callback_url` (server-side POST after terminal)
- stdout fallback for local demo

Production options:
- Kafka topic callback
- Webhook retry with signatures
- event bus integration

Future extension:
- Delivery plugin interface:
  - HTTP, Kafka, NATS, WebSocket

---

## 5) Auth / IAM

v0.1 does not enforce auth.

Production options:
- API key for submit/get/capacity endpoints
- OIDC/JWT validation
- per-workflow ACL (who can run which workflow)
- signed callbacks

Future extension:
- Auth integration module (OIDC providers)
- Multi-tenant isolation (namespaces)

---

## 6) Observability Stack

v0.1 provides Prometheus metrics and structured logs.

Recommended stack:
- Prometheus + Grafana (metrics)
- Loki/ELK (logs)
- OpenTelemetry (traces, future)

See `docs/observability.md` for PromQL panels.

---

## 7) Workflow Engines (Argo / K8s native)

Ordo does not aim to replace Argo.
Instead, Argo can be integrated as an executor/workflow backend:
- Ordo handles inference-centric IO + capacity admission + app modes
- Argo handles Kubernetes-native job orchestration

Future:
- "workflow plugin" interface with Argo adapter