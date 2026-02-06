# 🏛️ Governance

This document defines how Ordo is maintained and how decisions are made.

---

## 🎯 Project Goals
Ordo is an application-side multimodal inference hub:
- workflow orchestration (DAG)
- capacity-aware scheduling (multi-deployment + bounded queue)
- plugin-based executors and integrations
- observability-first operations

---

## 👥 Roles

### Maintainers
Maintainers:
- review and merge pull requests
- triage issues
- approve releases
- ensure project direction and quality

### Contributors
Contributors:
- open issues and PRs
- improve docs/examples
- propose new plugins and integrations

---

## ✅ Decision Making

We aim for **consensus**.
If consensus cannot be reached, maintainers decide by majority.

Major decisions (examples):
- changes to workflow spec
- breaking API changes
- plugin interface versioning
- release policy

---

## 🧾 Release Process (v0.1)

A release must satisfy:
- CI green (`make test`, `make e2e`)
- docs updated (README, demo, faq, observability)
- release notes written (`release-notes-*.md`)

Versioning:
- v0.x: rapid iteration; backward compatibility is best-effort
- v1.0: stable API compatibility guarantees

---

## 🧩 Scope & Boundaries

**Core** should remain small:
- workflow registry + execution model
- scheduler admission semantics
- engine invariants
- plugin interfaces

Everything else should be:
- plugins (executors/output/observability/artifact)
- integrations (k8s/cloud/auth/queues)

---

## 📜 Code of Conduct
All project participants must follow `CODE_OF_CONDUCT.md`.