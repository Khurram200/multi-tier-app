# Security — NetworkPolicy and RBAC

Requires Calico (or another enforcing CNI):

```powershell
minikube start --cni=calico
```

Apply with:

```powershell
.\k8s\deploy-security-monitoring.ps1
```

## NetworkPolicy

| Tier | Policy file | Rule |
|------|-------------|------|
| Frontend | `app-network-policies.yaml`, `network-policies.yaml` | May reach **backend:5000** only |
| Backend | `network-policies.yaml` | Egress to **database:5432**; ingress on **5000** |
| Database | both policy files | Ingress from **backend** only on **5432** |

Test:

```powershell
kubectl exec -n acme-todo deploy/frontend-deployment -- sh -c "nc -zv database 5432 2>&1 || echo BLOCKED"
```

## RBAC (least privilege per tier)

| ServiceAccount | Deployment | Role (least privilege) |
|----------------|------------|------------------------|
| `frontend-sa` | `frontend-deployment` | `get` ConfigMap `frontend-configmap` only |
| `backend-sa` | `backend-deployment` | `get` Secret `db-secret` only |
| `database-sa` | `db-deployment` | `get` PVC `db-pvc` only |
| `prometheus-sa` | `prometheus` | `list/watch` pods, services, endpoints in namespace |

Verify:

```powershell
kubectl auth can-i get secret/db-secret --as=system:serviceaccount:acme-todo:frontend-sa -n acme-todo
kubectl auth can-i get secret/db-secret --as=system:serviceaccount:acme-todo:backend-sa -n acme-todo
kubectl auth can-i get configmap/frontend-configmap --as=system:serviceaccount:acme-todo:frontend-sa -n acme-todo
```

Frontend should be **no** for secrets; backend should be **yes** for `db-secret`.

## Files

- `serviceaccounts.yaml` — one SA per tier (+ prometheus)
- `rbac.yaml` — Roles and RoleBindings
- `network-policies.yaml` — extended policies (prometheus, grafana, egress rules)

The root `rbac/` folder is a separate tutorial example; **coursework RBAC uses `k8s/security/`**.
