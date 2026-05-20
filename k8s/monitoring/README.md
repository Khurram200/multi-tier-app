# Monitoring — Prometheus & Grafana

## Deploy

After the application is running on Minikube:

```powershell
.\k8s\deploy-security-monitoring.ps1
```

This rebuilds the backend (adds `/metrics` via `prom-client`) and deploys Prometheus + Grafana.

---

## Task 3 — Access UIs

| Tool | NodePort | Open |
|------|----------|------|
| Prometheus | 30090 | `minikube service prometheus -n acme-todo --url` |
| Grafana | 30300 | `minikube service grafana -n acme-todo --url` |

**Grafana login:** `admin` / `admin` (change in production; local assessment only)

---

## Prometheus targets

1. Open Prometheus UI → **Status → Targets**
2. Confirm **`backend`** job is **UP** (`backend.acme-todo.svc:5000/metrics`)
3. Optional: **`kubernetes-pods`** shows pods with `prometheus.io/scrape=true`

### Sample queries (Prometheus Graph)

```promql
http_requests_total
rate(http_requests_total[1m])
process_cpu_seconds_total{job="backend"}
```

Generate traffic: use the todo app in the browser, then refresh graphs.

---

## Grafana dashboards

1. Log in to Grafana
2. **Dashboards** → browse folder **ACME Todo** → **ACME Todo - Backend HTTP**
3. Or **Explore** → datasource **Prometheus** → query `http_requests_total`

Pre-provisioned datasource points to `http://prometheus.acme-todo.svc.cluster.local:9090`.

### Built-in Kubernetes dashboards (optional)

If you install [metrics-server](https://github.com/kubernetes-sigs/metrics-server):

```powershell
minikube addons enable metrics-server
```

In Grafana **Explore**, you can also query cAdvisor/kubelet metrics if exposed — primary assessment path is the custom **backend** dashboard and Prometheus **Targets** view.

---

## Backend metrics exposed

| Metric | Type | Description |
|--------|------|-------------|
| `http_requests_total` | Counter | Requests by method, route, status |
| `process_*` | Default | CPU, memory, event loop (prom-client defaults) |

Endpoint: `GET /metrics` on the backend Service (port 5000).

---

## Teardown monitoring only

```powershell
kubectl delete deployment prometheus grafana -n acme-todo
kubectl delete svc prometheus grafana -n acme-todo
kubectl delete configmap prometheus-config grafana-datasources grafana-dashboards-provider grafana-dashboard-backend -n acme-todo
kubectl delete secret grafana-admin -n acme-todo
```
