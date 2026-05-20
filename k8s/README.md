# Kubernetes deployment (Minikube)

Deploy the three-tier To-Do app to a **local Minikube** cluster. Manifests mirror `docker-compose.yml`: **postgres**, **backend**, **frontend**.

## Task 1 — Minikube and kubectl

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) running
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

### Install Minikube (Windows)

```powershell
choco install minikube kubernetes-cli
# or: winget install Kubernetes.minikube
```

### Start cluster and verify kubectl

```powershell
minikube start --driver=docker --cpus=4 --memory=4096
kubectl cluster-info
kubectl get nodes
```

Expected: node status **Ready**.

---

## Task 2 — Manifest overview

| File | Kubernetes resources | Compose equivalent |
|------|---------------------|-------------------|
| `namespace.yaml` | Namespace `acme-todo` | project scope |
| `secret.yaml` | Secret (passwords) | `POSTGRES_PASSWORD`, `DB_PASSWORD` |
| `configmap.yaml` | ConfigMap + `init.sql` | env vars + `./db/init.sql` |
| `postgres-pvc.yaml` | PVC | volume `pgdata` |
| `postgres.yaml` | Deployment + Service `postgres` | service `database` |
| `backend.yaml` | Deployment + NodePort Service | service `backend` |
| `frontend.yaml` | Deployment + NodePort Service | service `frontend` |

**In-cluster DNS:** backend uses `DB_HOST=postgres` (Service name).  
**From your browser:** use Minikube IP + NodePort (not in-cluster names).

---

## Task 3 — Build images inside Minikube

Images must be built in Minikube’s Docker daemon (`imagePullPolicy: Never`).

```powershell
cd C:\Users\khurr\Documents\multi-tier-app

minikube start

# Point shell Docker CLI at Minikube
minikube docker-env --shell powershell | Invoke-Expression

docker build -t todo-backend:latest ./backend
docker build -t todo-frontend:latest ./web

docker images | Select-String "todo-"
```

---

## Deploy application

### Option A — Automated script (recommended)

```powershell
cd C:\Users\khurr\Documents\multi-tier-app
.\k8s\deploy.ps1
```

### Option B — Manual steps

```powershell
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres.yaml

kubectl wait --for=condition=ready pod -l app=postgres -n acme-todo --timeout=180s

kubectl apply -f k8s/backend.yaml
kubectl wait --for=condition=ready pod -l app=backend -n acme-todo --timeout=180s

# Set API URL for browser (Minikube IP + backend NodePort 30050)
$ip = minikube ip
kubectl patch configmap app-config -n acme-todo --type merge -p "{`"data`":{`"REACT_APP_API_URL`":`"http://${ip}:30050/api/todos`"}}"
kubectl rollout restart deployment/frontend -n acme-todo

kubectl apply -f k8s/frontend.yaml
kubectl wait --for=condition=ready pod -l app=frontend -n acme-todo --timeout=300s
```

---

## Verify services

```powershell
kubectl get all -n acme-todo
kubectl get pods -n acme-todo
kubectl logs deployment/backend -n acme-todo
kubectl logs deployment/frontend -n acme-todo
```

| Check | Command |
|-------|---------|
| Backend health (inside cluster) | `kubectl exec -n acme-todo deploy/backend -- node -e "require('http').get('http://127.0.0.1:5000/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"` |
| API via NodePort | `minikube service backend -n acme-todo --url` then append `/api/todos` |
| Open UI | `minikube service frontend -n acme-todo --url` |

Or in browser:

- Frontend: `http://<minikube ip>:30030`
- Backend API: `http://<minikube ip>:30050/api/todos`

Get IP: `minikube ip`

---

## Architecture (cluster)

```
Namespace: acme-todo
┌─────────────────────────────────────────────────────────────┐
│  Service: frontend (NodePort 30030)                         │
│       Deployment: frontend  →  todo-frontend:latest         │
│              │ HTTP (browser → Minikube IP:30050)          │
│              ▼                                              │
│  Service: backend (NodePort 30050, ClusterIP :5000)         │
│       Deployment: backend   →  todo-backend:latest          │
│              │ DB_HOST=postgres:5432                        │
│              ▼                                              │
│  Service: postgres (ClusterIP :5432)                        │
│       Deployment: postgres  →  postgres:18-alpine           │
│              PVC: postgres-pvc                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `ImagePullBackOff` | Rebuild images after `minikube docker-env \| Invoke-Expression` |
| Backend `CrashLoopBackOff` | `kubectl logs deploy/backend -n acme-todo` — often DB not ready; wait for postgres pod |
| Frontend loads, no todos | Patch `REACT_APP_API_URL` in ConfigMap with `minikube ip` and restart frontend |
| Postgres pod pending | `minikube addons enable storage-provisioner` |
| Reset cluster | `minikube delete && minikube start` then redeploy |

---

## Teardown

```powershell
kubectl delete namespace acme-todo
# or delete cluster:
minikube stop
minikube delete
```

---

## Logbook

Document Minikube setup, `kubectl get pods`, service URLs, and screenshots in **Technical Logbook — Entry 3**.

## Security and monitoring

After the app is deployed, use **Calico** for NetworkPolicy and run:

```powershell
.\k8s\deploy-security-monitoring.ps1
```

See [security/README.md](security/README.md) and [monitoring/README.md](monitoring/README.md). Logbook: **Entry 4**.
