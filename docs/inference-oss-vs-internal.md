# 🔐 Inference OSS vs Internal

Ordo is designed to support both:
- **Ordo Inference**: a reusable industrial-grade inference orchestration framework
- **Ordo Internal**: a company deployment with proprietary workflows, plugins, and integrations

This document clarifies what should be open sourced and what should remain private.

---

## ✅ What belongs in Inference

### 1) Core contracts and semantics
- workflow spec and validation rules
- execution model (task_id, stage state, artifacts/metadata)
- scheduler semantics:
  - atomic admission
  - bounded queue (B+)
  - multi-deployment routing + failover
- execution modes:
  - SYNC / ASYNC / STREAM

### 2) Safe reference plugins
- HTTP executor plugin (generic)
- Local executor plugin (demo/testing)
- SSE output plugin
- minimal observability (Prometheus)

### 3) Safe demo workflows
Examples are meant to teach usage, not expose proprietary pipelines:
- `llm.chat` (calls generic LLM API via HTTP executor)
- `t2i.then.i23d` (chaining two HTTP APIs)
- `i23d.pipeline` (local demo pipeline)

---

## 🔒 What should remain internal

### 1) Proprietary workflows
- real 3D pipelines for production
- company-specific preprocessing, PBR, texture, post-processing
- internal stage wiring and param schema that reveal business logic

### 2) Proprietary executor plugins
- GPU services or in-house model endpoints
- internal authentication / signing logic
- private scheduling logic tied to business constraints

### 3) Internal integrations
- private network topology
- internal object storage schemes / tenancy
- internal queues and observability pipelines

---

## 🧩 Recommended split strategy

### Inference repository
- `core/` contains stable contracts and invariants
- `plugins/` contains safe reference implementations
- `integrations/` contains generic examples (k8s/auth stubs)

### Internal repository
- add private workflows and plugins as separate modules/repos
- keep Inference clean and runnable with demo workflows
- treat proprietary logic as “integrations” layered on top of Inference

---

## 🏁 Practical guideline

If a workflow/plugin reveals:
- model architecture
- internal algorithm steps
- business-sensitive parameters
- private infra topology
then it should be internal only.

Inference should focus on:
- usability
- correctness
- extensibility
- industrial-grade foundations