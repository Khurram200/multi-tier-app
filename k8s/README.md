# Kubernetes (Minikube)

Manifest layout matches **`multi-tier-app - Copy/k8s`** — one file per resource.

**Namespace:** `acme-todo`

## Layout

| File | Resource |
| ---- | -------- |
| `namespace.yaml` | Namespace |
| `db-secret.yaml` | Secret (Postgres credentials) |
| `db-init-script-configmap.yaml` | Schema + seed data (`db/init.sql`) |
| `db-pvc.yaml` | PersistentVolumeClaim |
| `db-deployment.yaml` | Postgres 18 |
| `db-service.yaml` | Service `database` (same hostname as Compose) |
| `backend-deployment.yaml` | Express API |
| `backend-service.yaml` | NodePort **30050** |
| `frontend-configmap.yaml` | `REACT_APP_API_URL` |
| `frontend-deployment.yaml` | React UI |
| `frontend-service.yaml` | NodePort **30030** |
| `app-network-policies.yaml` | Frontend→backend, backend→database |
| `deploy.ps1` | Build images + apply all of the above |

**RBAC** (separate folder, like the Copy project): `../rbac/`

**Monitoring:** `monitoring/` (Prometheus + Grafana)

## Deploy

```powershell
minikube start --driver=docker --cpus=4 --memory=6144 --cni=calico
.\k8s\deploy.ps1
kubectl get pods -n acme-todo
minikube service frontend-service -n acme-todo --url
```

## Security + monitoring

```powershell
.\k8s\deploy-security-monitoring.ps1
```

## Clean up

```powershell
kubectl delete namespace acme-todo
```
