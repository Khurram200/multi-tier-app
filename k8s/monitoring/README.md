# Monitoring — Prometheus and Grafana

For the monitoring section of the module I added Prometheus and Grafana to the same Minikube namespace.

## Deploy

Run from the project root (includes security manifests too):

```powershell
.\k8s\deploy-security-monitoring.ps1
```

The backend was updated to expose `/metrics` using the `prom-client` npm package.

## How to view

```powershell
minikube service prometheus -n acme-todo --url
minikube service grafana -n acme-todo --url
```

**Grafana login (local):** admin / admin

In Prometheus: **Status → Targets** — check the backend target is **UP**.

In Grafana: open the **ACME Todo - Backend HTTP** dashboard, or use Explore with queries like `http_requests_total`.

Use the todo app in the browser first so there is some traffic to graph.

## What is measured

- `http_requests_total` — number of API requests  
- Default Node.js process metrics from prom-client  
