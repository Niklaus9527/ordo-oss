# Deployment

This doc describes recommended deployment patterns for Ordo.

## Local (Single Process)
- Ordo server runs locally
- Examples use mock external APIs

## Container
- Package Ordo into a Docker image
- Use env vars for provider endpoints and secrets

## Kubernetes (Recommended for Production)
- Run Ordo as a Deployment with 2-3 replicas
- Use readinessProbe + preStop for graceful shutdown
- Expose `/metrics` for Prometheus

### Graceful Upgrade (v0.1)
- Use rolling update
- On shutdown:
  - stop accepting new requests (draining)
  - wait a short window for inflight to complete
  - streams may disconnect; clients should reconnect if needed

## Multi-Cloud Pattern
- Ordo control-plane can be centralized
- Executors/services run in each cloud/region
- Deployments represent remote capacity pools per cloud
- Routing policy decides traffic split and failover