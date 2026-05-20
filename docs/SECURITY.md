# Security design — ACME Todo (local Kubernetes)

**Student:** Khurram Farooqui (2325493)

## Principles

1. **Defense in depth** — network segmentation + RBAC + secrets outside images  
2. **Least privilege** — each tier has its own ServiceAccount with minimal API permissions  
3. **Fail closed** — NetworkPolicy default deny for selected pods; only explicit paths allowed  

## Network segmentation

```
Browser ──NodePort──► frontend:3000
Browser ──NodePort──► backend:5000 ──► postgres:5432
frontend pod ──X──► postgres:5432   (blocked by NetworkPolicy)
```

Postgres accepts connections **only** from pods labeled `app: backend`.

## RBAC

Application pods do not require cluster-admin. Roles are namespace-scoped (`acme-todo`):

- Frontend cannot read Secrets  
- Backend can read only `app-secrets` and `app-config` by name  
- Prometheus can list/watch pods for scraping in this namespace only  

## Secrets management

| Secret | Storage | Consumption |
|--------|---------|-------------|
| DB passwords | Kubernetes Secret `app-secrets` | Env vars on postgres/backend pods |
| Grafana admin | Secret `grafana-admin` | Grafana deployment env |

Do not commit production passwords to git. Local assessment values are documented in `k8s/secret.yaml` for Minikube only.

## Container hardening (from containerization phase)

- Non-root `USER node` in application images  
- Multi-stage builds to reduce image size and attack surface  
- `.dockerignore` excludes `.env` from build context  

## Monitoring security

- Prometheus scrapes backend inside the cluster (NetworkPolicy allows prometheus → backend:5000)  
- Grafana queries Prometheus only; no direct DB access  

## Verification commands

Document results in **Technical Logbook Entry 4**.

```powershell
kubectl auth can-i get secrets/app-secrets --as=system:serviceaccount:acme-todo:frontend-sa -n acme-todo
kubectl exec -n acme-todo deploy/frontend -- sh -c "nc -zv postgres 5432 2>&1 || echo BLOCKED"
```

## Future improvements

- TLS Ingress (cert-manager)  
- Sealed Secrets or external secret store  
- Pod Security Standards / restricted SCC  
- Replace plaintext Secret manifests with `kubectl create secret` in CI  
