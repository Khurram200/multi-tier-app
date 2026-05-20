# Security — NetworkPolicy & RBAC

## Prerequisites

NetworkPolicy enforcement requires a compatible CNI on Minikube:

```powershell
minikube delete
minikube start --driver=docker --cpus=4 --memory=6144 --cni=calico
```

Redeploy the app: `.\k8s\deploy.ps1` then `.\k8s\deploy-security-monitoring.ps1`

---

## Task 1 — NetworkPolicy (tier isolation)

| Policy | Pod | Allows | Blocks |
|--------|-----|--------|--------|
| `postgres-network-policy` | postgres | Ingress **only** from `app: backend` on **5432** | Frontend → DB, external → DB |
| `backend-network-policy` | backend | Ingress on **5000** (API + metrics); egress to **postgres:5432** + DNS | Backend → arbitrary internet |
| `frontend-network-policy` | frontend | Ingress on **3000**; egress **DNS only** | Frontend pod → postgres |
| `prometheus-network-policy` | prometheus | Scrape backend; UI on **9090** | — |
| `grafana-network-policy` | grafana | UI on **3000**; query Prometheus | — |

**Note:** The React UI calls the API from the **browser** via NodePort (`30050`), not from the frontend pod. The policy blocks **pod-to-pod** access from frontend → postgres, which is the assessment requirement.

### Verify isolation

```powershell
# Should fail (timeout / no route) when Calico is active:
kubectl exec -n acme-todo deploy/frontend -- sh -c "nc -zv postgres 5432 2>&1 || echo BLOCKED"

# Should succeed from backend:
kubectl exec -n acme-todo deploy/backend -- sh -c "nc -zv postgres 5432"
```

---

## Task 2 — RBAC (least privilege)

| ServiceAccount | Role | Permissions |
|----------------|------|-------------|
| `frontend-sa` | `frontend-app-role` | `get` ConfigMap `app-config` only |
| `backend-sa` | `backend-app-role` | `get` ConfigMap `app-config`, `get` Secret `app-secrets` |
| `postgres-sa` | `postgres-app-role` | `get` PVC `postgres-pvc` only |
| `prometheus-sa` | `prometheus-scrape-role` | `get/list/watch` pods, services, endpoints in namespace |

No ClusterRole bindings for application tiers — scope limited to `acme-todo`.

### Verify RBAC

```powershell
kubectl auth can-i get secrets/app-secrets --as=system:serviceaccount:acme-todo:backend-sa -n acme-todo
kubectl auth can-i get secrets/app-secrets --as=system:serviceaccount:acme-todo:frontend-sa -n acme-todo
# expect: yes for backend, no for frontend
```

---

## Apply

```powershell
kubectl apply -f k8s/security/
```

Or use `.\k8s\deploy-security-monitoring.ps1` (includes monitoring).

See [docs/SECURITY.md](../../docs/SECURITY.md) for the written security rationale.
