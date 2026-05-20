# Project plan — ACMEInnovateNow

**Student:** Khurram Farooqui (2325493)  
**Issue date:** 29 April 2026  
**Submission deadline:** 29 May 2026  
**Duration:** 4 weeks (30 days)

---

## Overview

| Milestone | Target date | Logbook entry |
|-----------|-------------|---------------|
| Setup & initial exploration | 5 May 2026 | Entry 1 |
| Containerization & Compose | 12 May 2026 | Entry 2 |
| Local Kubernetes & security | 19 May 2026 | Entry 3 |
| Monitoring, serverless & docs | 26 May 2026 | Entry 4 |
| Final review & submission | **29 May 2026** | Entry 5 (summary) |

---

## Current progress (update weekly)

| Area | Status | Notes |
|------|--------|-------|
| Docker Desktop | In progress | Client installed; ensure daemon running before each session |
| Docker tutorials | _[ ]_ | Complete self-study; log in Entry 1 |
| Run app without containers | _[ ]_ | See `SETUP_LOCAL_WITHOUT_DOCKER.md` |
| Dockerfiles (backend, web) | Done | Multi-stage Node 20 pattern |
| `docker compose up` | Done | DB healthy, backend + frontend compile |
| Technical Logbook Entry 1 | In progress | Name/ID added; fill dates and results |
| Kubernetes manifests | Done | `k8s/` + `deploy.ps1` — run on Minikube |
| Security (NetworkPolicy, RBAC) | Done | `k8s/security/` — requires Calico CNI |
| Monitoring (Prometheus/Grafana) | Done | `k8s/monitoring/` + backend `/metrics` |
| Serverless (OpenFaaS) | Done | `serverless/openfaas/todo-notify` |
| Edge (K3s / k3d) | Done | `edge/setup-edge.ps1` |
| Project report | Done | `docs/PROJECT_REPORT.md` |
| Portfolio / video checklist | Done | `docs/PORTFOLIO_SUBMISSION.md` |

---

## Week 1 — 29 Apr → 5 May 2026  
**Theme: Setup and initial exploration**

### Goals

- [ ] Docker Desktop installed and verified (`docker version`, `hello-world`)
- [ ] Complete introductory Docker tutorials (self-study plan)
- [ ] Run app **without** containers (Postgres + `npm start` in `backend` and `web`)
- [ ] Complete **Technical Logbook — Entry 1** (setup, architecture, reflections)

### Tasks (checklist)

| Day | Task | Deliverable |
|-----|------|-------------|
| 29–30 Apr | Install/start Docker Desktop; run tutorials (images, run, ps) | Logbook §1–2 |
| 1–2 May | Tutorials (Dockerfile, volumes); explore repo structure | Logbook §2 |
| 3 May | Local Postgres + `db/init.sql`; start backend & frontend | Logbook §3 run log |
| 4 May | Test CRUD in browser; draw/document 3-tier diagram | Logbook §4 |
| 5 May | Review Entry 1; fix any local run issues | **Entry 1 complete** |

### Reference

- `docs/SETUP_LOCAL_WITHOUT_DOCKER.md`
- `docs/TECHNICAL_LOGBOOK.md` → Entry 1

---

## Week 2 — 6 May → 12 May 2026  
**Theme: Containerization**

### Goals

- [ ] Stable `docker compose up --build` (all services healthy)
- [ ] Document image build decisions (multi-stage, non-root user)
- [ ] Optional: production-style frontend image (`npm run build` + nginx)
- [ ] Backend `/health` and `/ready` endpoints for orchestration
- [ ] **Technical Logbook — Entry 2**

### Tasks

| Day | Task | Deliverable |
|-----|------|-------------|
| 6–7 May | Verify Dockerfiles; fix port/password issues; `.env.example` | Working compose stack |
| 8 May | Add health endpoints to `backend/server.js` | Probe-ready API |
| 9 May | Document Compose networking (`database`, `backend`, ports) | Logbook Entry 2 |
| 10–11 May | `docker compose` troubleshooting notes; image size / layer review | Logbook + screenshots |
| 12 May | **Entry 2 complete** | Containerization phase signed off |

### Commands to record in logbook

```powershell
docker compose build
docker compose up
docker compose ps
docker compose logs backend
```

---

## Week 3 — 13 May → 19 May 2026  
**Theme: Local Kubernetes & security**

### Goals

- [ ] Local cluster running (**kind** or **minikube** or Docker Desktop Kubernetes)
- [ ] `k8s/` manifests: Namespace, Deployments, Services, Secrets, ConfigMaps
- [ ] Postgres on cluster (StatefulSet or Helm Bitnami chart)
- [ ] Ingress or NodePort for browser access
- [ ] Liveness/readiness probes using `/health` and `/ready`
- [ ] Basic security: K8s Secrets (no passwords in git), optional NetworkPolicy
- [ ] **Technical Logbook — Entry 3**

### Tasks

| Day | Task | Deliverable |
|-----|------|-------------|
| 13 May | Install kind/minikube; `kubectl cluster-info` | Cluster running |
| 14–15 May | Backend + frontend Deployments/Services | Apps scheduled |
| 16 May | DB + Secrets + ConfigMaps; test API from inside cluster | Data layer works |
| 17 May | Ingress/NodePort; access UI from host | End-to-end on K8s |
| 18 May | Security doc: secrets, non-root, CORS, resource limits | `docs/SECURITY.md` draft |
| 19 May | **Entry 3 complete** | K8s + security phase |

### Suggested repo layout

```
k8s/
  namespace.yaml
  secret.yaml          # from template; real values applied locally only
  configmap.yaml
  postgres.yaml
  backend.yaml
  frontend.yaml
  ingress.yaml
```

---

## Week 4 — 20 May → 26 May 2026  
**Theme: Monitoring, serverless & professional documentation**

### Goals

- [ ] Prometheus scraping metrics (e.g. `prom-client` on backend `/metrics`)
- [ ] Grafana dashboard (request rate, errors, or pod metrics)
- [ ] One **serverless** demonstration with written justification (Knative or OpenFaaS locally)
- [ ] `docs/ARCHITECTURE.md`, `docs/DECISIONS.md` (ADRs), updated README
- [ ] **Technical Logbook — Entry 4**

### Tasks

| Day | Task | Deliverable |
|-----|------|-------------|
| 20–21 May | Deploy Prometheus + Grafana (Helm or manifests) | Metrics visible |
| 22 May | Instrument backend; verify targets in Prometheus | `/metrics` working |
| 23 May | Serverless function + ADR (“why not full serverless”) | `serverless/` or doc |
| 24–25 May | Architecture diagrams; monolith → cloud-native narrative | `docs/ARCHITECTURE.md` |
| 26 May | **Entry 4 complete** | Advanced topics documented |

---

## Final days — 27 May → 29 May 2026  
**Theme: Submission readiness**

### 27 May — Integration test

- [ ] Fresh machine test: clone repo → README steps → app works (Compose **or** K8s path documented)
- [ ] All logbook entries dated and consistent
- [ ] No secrets committed (check `.env`, `secret.yaml` uses templates only)

### 28 May — Polish

- [ ] Proofread `TECHNICAL_LOGBOOK.md` and project docs
- [ ] Export/screenshot: Compose `ps`, K8s `kubectl get all`, Grafana panel
- [ ] **Entry 5:** Executive summary (problem, approach, outcomes, lessons learned)

### 29 May — **Submission deadline**

- [ ] Submit repository link / archive per course instructions
- [ ] Confirm deadline timezone (e.g. 23:59 local / UK time — check brief)

---

## Submission package checklist

| Item | Location |
|------|----------|
| Technical Logbook (all entries) | `docs/TECHNICAL_LOGBOOK.md` |
| How to run locally (no Docker) | `docs/SETUP_LOCAL_WITHOUT_DOCKER.md` |
| How to run with Compose | `README.md` |
| How to run on Kubernetes | `README.md` + `k8s/README.md` |
| Architecture & decisions | `docs/ARCHITECTURE.md`, `docs/DECISIONS.md` |
| Security | `docs/SECURITY.md` |
| Source + Dockerfiles + compose + k8s | Repository root |

---

## If you are behind schedule (compressed plan)

Use this **minimum viable path** before **29 May**:

| Priority | Must deliver | Est. time |
|----------|--------------|-----------|
| P0 | Entry 1 complete + Compose demo works | 1 day |
| P0 | Entry 2 + health endpoints | 1 day |
| P1 | K8s deploy (simplified: 3 deployments + services) | 2–3 days |
| P1 | Entry 3 + basic SECURITY.md | 1 day |
| P2 | Prometheus + one Grafana panel OR kube metrics | 1–2 days |
| P2 | Short serverless ADR + minimal demo OR documented “deferred with rationale” | 1 day |
| P0 | Entry 5 summary + README | 1 day |

**Do not skip:** Logbook, Compose, K8s, and written justification of decisions — these are usually core rubric items.

---

## Weekly time budget (suggested)

| Week | Hours/week | Focus |
|------|------------|--------|
| 1 | 6–8 h | Docker learning + bare-metal run + Entry 1 |
| 2 | 6–8 h | Compose hardening + Entry 2 |
| 3 | 8–10 h | Kubernetes + security + Entry 3 |
| 4 | 8–10 h | Monitoring + serverless + docs + Entry 4–5 |

**Total:** ~30–36 hours over the month (adjust to your course guidance).

---

## Link to logbook

After each week, update:

1. `docs/TECHNICAL_LOGBOOK.md` — new entry with date and evidence  
2. `docs/PROJECT_PLAN.md` — **Current progress** table at top  

**Next action today:** Complete Entry 1 §1–3 if not done; confirm `docker compose up` still works; schedule Week 3 K8s setup on your calendar before 19 May.
