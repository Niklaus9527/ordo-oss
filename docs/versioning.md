# Versioning

Ordo uses SemVer for framework releases and explicit versioning for workflows.

## Ordo Framework Versioning (SemVer)
- `vMAJOR.MINOR.PATCH`
- Breaking API changes require major bump.

## Workflow Versioning
Workflow versions (e.g., `v1.0`, `v1.5`, `v2.0`) represent:
- DAG structure evolution
- input/output schema evolution
- execution semantics changes

### Compatibility Guidelines
- Adding optional input fields: minor bump (e.g., v1.0 → v1.1)
- Removing/renaming fields or changing semantics: major bump (e.g., v1.x → v2.0)
- Output contract changes: treat as breaking unless strictly additive

## Stage Naming vs Implementation
Stage IDs are semantic (e.g., `preprocess`, `geometry`, `texture`).
Different workflow versions may reuse stage IDs but have different implementations.

Implementation binding is controlled via configuration:
- `(workflow_id, version, stage_id) -> executor endpoint/plugin behavior`

Do not encode provider or cloud details into stage IDs.

## Deployment Versioning
Deployments represent runtime pools and can be revised independently:
- `v2.0-volc-geom`
- `v2.0-tx-tex`
- canary suffix: `...-canary`

Routing policy controls traffic split and failover.

## Artifacts
Artifacts should be URI-first.
Bytes are allowed only for demos/small payloads and should be restricted via configuration in production.