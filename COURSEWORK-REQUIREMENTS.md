# Coursework requirements — evidence map

**Student:** Khurram Farooqui (2325493) · **Module:** Cloud Technologies  
**Repository:** https://github.com/Khurram200/multi-tier-app

All evidence below is in **this repository**. The technical logbook and written report are submitted in the portfolio archive alongside this repo.

---

## Phase 1 — Setup and initial exploration

| Task | Status | Evidence in this repo |
|------|--------|------------------------|
| 1. Install Docker Desktop and verify it runs | Done | `README.md` (Requirements) — `docker version` |
| 2. Complete introductory Docker tutorials | Done | Documented in portfolio Technical Logbook |
| 3. Clone boilerplate; run locally without containers | Done | `README.md` §2 |
| 4. Begin Technical Logbook | Done | Portfolio `Technical-Logbook.md` |

---

## Phase 2 — Foundational containerization

| Task | Status | Evidence in this repo |
|------|--------|------------------------|
| 1. Dockerfiles (multi-stage, non-root) | Done | `backend/Dockerfile`, `web/Dockerfile` |
| 2. `docker-compose.yml` (3 services, network, volume) | Done | `docker-compose.yml` |
| 3. Single `docker compose up` | Done | `README.md` §1 |

```powershell
docker compose up --build
```

---

## Phase 3 — Orchestration with Kubernetes

| Task | Status | Evidence in this repo |
|------|--------|------------------------|
| 1. Minikube + kubectl | Done | `k8s/README.md`, `k8s/deploy.ps1` |
| 2. Deployments + Services | Done | `k8s/postgres.yaml`, `backend.yaml`, `frontend.yaml` |
| 3. Deploy and verify communication | Done | `DB_HOST=postgres` in ConfigMap; NodePorts 30030 / 30050 |

```powershell
minikube start --driver=docker --cpus=4 --memory=6144 --cni=calico
.\k8s\deploy.ps1
kubectl get pods -n acme-todo
```

---

## Phase 4 — Security and monitoring

| Task | Status | Evidence in this repo |
|------|--------|------------------------|
| 1. NetworkPolicy tier isolation | Done | `k8s/security/network-policies.yaml` |
| 2. RBAC (Roles + RoleBindings) | Done | `k8s/security/rbac.yaml` |
| 3. Prometheus + Grafana | Done | `k8s/monitoring/`; backend `/metrics` |

```powershell
.\k8s\deploy-security-monitoring.ps1
```

---

## Phase 5 — Advanced architectures

| Task | Status | Evidence in this repo |
|------|--------|------------------------|
| 1. OpenFaaS + event-driven function | Done | `serverless/openfaas/` |
| 2. K3s edge (k3d) + lightweight service | Done | `edge/setup-edge.ps1`, `edge/k8s/edge-health.yaml` |
| 3. Logbook + Comprehensive Report | Done | Portfolio folder (submitted with zip) |
| 4. Demonstration video | Student | Record and add URL to portfolio cover sheet |

```powershell
.\serverless\openfaas\install-openfaas.ps1
.\edge\setup-edge.ps1
```

---

## Quick verification before submission

- [ ] `docker compose up --build` — UI and API work  
- [ ] `.\k8s\deploy.ps1` — all pods Ready in `acme-todo`  
- [ ] `.\k8s\deploy-security-monitoring.ps1` — Grafana dashboard loads  
- [ ] OpenFaaS function deployed (see `serverless/openfaas/README.md`)  
- [ ] Edge URL http://localhost:8088 responds after `.\edge\setup-edge.ps1`
