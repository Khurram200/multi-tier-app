# OpenFaaS — event-driven serverless function

**Function:** `todo-notify` — validates todo titles asynchronously (HTTP-triggered, event-style workload).

## Architecture

```
Backend POST /api/todos  ──optional webhook──►  OpenFaaS Gateway  ──►  todo-notify function
Browser / API client     ──direct test──────►  OpenFaaS Gateway  ──►  todo-notify function
```

Long-running CRUD stays on Kubernetes Deployments; bursty validation/notifications fit serverless.

---

## Task 1 — Install OpenFaaS on Minikube

### Prerequisites

- Minikube running
- `kubectl` configured
- [arkade](https://github.com/alexellis/arkade) (recommended) or Helm

### Install (arkade)

```powershell
arkade install openfaas
```

Or with Helm:

```powershell
kubectl create namespace openfaas
kubectl create namespace openfaas-fn

helm repo add openfaas https://openfaas.github.io/faas-netes/
helm repo update
helm upgrade openfaas openfaas/openfaas `
  --install `
  --namespace openfaas `
  --set functionNamespace=openfaas-fn `
  --set generateBasicAuth=true

# Get gateway password
$secret = kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($secret))
```

Wait for pods:

```powershell
kubectl get pods -n openfaas
kubectl get pods -n openfaas-fn
```

### Port-forward gateway (local access)

```powershell
kubectl port-forward -n openfaas svc/gateway 8080:8080
```

UI: http://127.0.0.1:8080  
Login: `admin` + password from secret above.

---

## Deploy `todo-notify` function

### Option A — faas-cli (recommended)

```powershell
# Install CLI: arkade install faas-cli
cd serverless/openfaas

# Build image inside Minikube Docker
minikube docker-env --shell powershell | Invoke-Expression
faas-cli build -f todo-notify.yml
faas-cli deploy -f todo-notify.yml --gateway http://127.0.0.1:8080
```

### Option B — Manual image + OpenFaaS UI

```powershell
minikube docker-env --shell powershell | Invoke-Expression
docker build -t todo-notify:latest ./serverless/openfaas/todo-notify
```

Deploy via OpenFaaS UI → **Deploy New Function** → image `todo-notify:latest`, port 8080.

---

## Invoke (event-driven test)

With gateway port-forward running:

```powershell
# Valid event
curl -X POST http://127.0.0.1:8080/function/todo-notify `
  -H "Content-Type: application/json" `
  -d '{"title":"Learn OpenFaaS"}'

# Rejected event (empty title)
curl -X POST http://127.0.0.1:8080/function/todo-notify `
  -H "Content-Type: application/json" `
  -d '{"title":""}'
```

Expected: JSON with `event: todo-notify-accepted` or `todo-notify-rejected`.

---

## Optional: wire backend webhook

Set on backend Deployment / Compose:

```
OPENFAAS_TODO_NOTIFY_URL=http://gateway.openfaas.svc.cluster.local:8080/function/todo-notify
```

Backend fires async POST after creating a todo (non-blocking). See `backend/server.js`.

For local port-forward from cluster, use kubectl port-forward or install gateway in same cluster network.

---

## Logbook

Record install commands, `faas-cli list`, curl output, and screenshot of OpenFaaS UI in **Entry 5**.
