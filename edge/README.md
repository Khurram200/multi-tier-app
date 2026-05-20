# Edge computing simulation — K3s in Docker (k3d)

Simulates a **resource-constrained edge node** using **K3s** (lightweight Kubernetes) inside Docker via **[k3d](https://k3d.io/)** — K3s packaged for local edge/IoT-style deployments.

## Task 2 — Setup edge cluster

### Install k3d

```powershell
choco install k3d
# or: winget install k3d
```

### Create edge cluster (single server, minimal resources)

```powershell
.\edge\setup-edge.ps1
```

Or manually:

```powershell
k3d cluster create acme-edge `
  --servers 1 `
  --agents 0 `
  --api-port 6551 `
  --port "8088:80@loadbalancer"

kubectl config use-context k3d-acme-edge
kubectl apply -f edge/k8s/edge-health.yaml
kubectl wait --for=condition=available deployment/edge-health -n edge --timeout=120s
kubectl get pods -n edge -o wide
```

### Access lightweight service

```powershell
curl http://localhost:8088
# or
kubectl get svc -n edge
```

Browser: **http://localhost:8088** — shows edge health page.

---

## Why K3s / k3d for edge?

| Property | Full K8s (Minikube) | K3s edge (k3d) |
|----------|---------------------|----------------|
| Memory footprint | Higher | Lower (single binary) |
| Use case | Cloud / dev cluster | Edge, IoT, CI, ARM nodes |
| This demo | Full todo stack | Lightweight nginx status only |

The **full application** runs on Minikube; the **edge node** runs a minimal **edge-health** service to show tiered topology (cloud core vs edge site).

---

## Architecture

```
┌──────────────────── Minikube (core) ────────────────────┐
│  frontend | backend | postgres | prometheus | grafana    │
│  OpenFaaS (serverless)                                   │
└─────────────────────────────────────────────────────────┘

┌──────────────── k3d / K3s (edge) ─────────────────────┐
│  edge-health (nginx alpine, 16–32Mi RAM limit)          │
│  http://localhost:8088                                 │
└────────────────────────────────────────────────────────┘
```

---

## Teardown

```powershell
k3d cluster delete acme-edge
```

---

## Logbook

Document cluster create, `kubectl get pods -n edge`, and curl/browser screenshot in **Entry 5**.
