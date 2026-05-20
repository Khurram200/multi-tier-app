# Portfolio submission checklist

**Student:** Khurram Farooqui  
**Student number:** 2325493  
**Submission deadline:** 29 May 2026  

Use this checklist before submitting your **complete portfolio** as a **single compressed archive** (per module brief).

---

## Four portfolio components (required)

| # | Component | What to include | This repo |
|---|-----------|-----------------|-----------|
| **1** | **Professional-grade Git repository** | All IaC (Dockerfiles, K8s manifests, Compose, scripts) + **README.md** with deployment instructions | Root `README.md`, `k8s/`, `docker-compose.yml`, etc. |
| **2** | **Technical Logbook** | Setup through final phase with evidence | `docs/TECHNICAL_LOGBOOK.md` |
| **3** | **Comprehensive Project Report** | Architecture, decisions, outcomes | `docs/PROJECT_REPORT.md` |
| **4** | **Demonstration video** | Working system walkthrough | Record separately; link in cover sheet |

---

## Component 1 — Git repository checklist

| Item | Path | Done |
|------|------|------|
| Root README with full deployment instructions | `README.md` | [ ] |
| Docker Compose IaC | `docker-compose.yml` | [ ] |
| Backend Dockerfile + `.dockerignore` | `backend/` | [ ] |
| Frontend Dockerfile + `.dockerignore` | `web/` | [ ] |
| Kubernetes manifests | `k8s/*.yaml` | [ ] |
| Security IaC (NetworkPolicy, RBAC) | `k8s/security/` | [ ] |
| Monitoring IaC | `k8s/monitoring/` | [ ] |
| Serverless IaC | `serverless/openfaas/` | [ ] |
| Edge IaC | `edge/k8s/` | [ ] |
| `.gitignore` (no `node_modules`, `.env`) | `.gitignore` | [ ] |
| Clone → deploy tested on clean machine | — | [ ] |

---

## Other deliverables (inside same archive)

| # | Deliverable | Location / format | Done |
|---|-------------|-------------------|------|
| 2 | Technical Logbook (entries 1–5) | `docs/TECHNICAL_LOGBOOK.md` | [ ] |
| 3 | Comprehensive Project Report | `docs/PROJECT_REPORT.md` | [ ] |
| 4 | Demonstration video | MP4 / unlisted URL | [ ] |

---

## Technical Logbook entries (must be complete)

| Entry | Phase | Date filled | Evidence attached |
|-------|-------|-------------|-------------------|
| 1 | Setup & exploration | [ ] | [ ] |
| 2 | Containerization | [ ] | [ ] |
| 3 | Kubernetes / Minikube | [ ] | [ ] |
| 4 | Security & monitoring | [ ] | [ ] |
| 5 | Serverless, edge, final summary | [ ] | [ ] |

---

## Demonstration video outline (Task 4)

Record screen + voice. Suggested **8–10 minute** structure:

| Time | Content | Commands / visuals |
|------|---------|-------------------|
| 0:00 | Introduction | Name, ID, project title |
| 0:30 | Architecture | Show diagram (report or draw.io) |
| 1:00 | Docker Compose | `docker compose up --build`, browser CRUD |
| 2:30 | Minikube deploy | `kubectl get pods -n acme-todo`, open frontend URL |
| 4:00 | Security | NetworkPolicy test blocked; `kubectl auth can-i` |
| 5:00 | Monitoring | Prometheus targets UP; Grafana dashboard |
| 6:00 | OpenFaaS | Port-forward gateway; `curl` todo-notify function |
| 7:00 | Edge K3s | `k3d cluster list`, `curl localhost:8088` |
| 8:30 | Conclusion | Lessons learned; pointer to report & logbook |

**Recording tips:**

- Zoom browser to 125% for readability  
- Hide unrelated desktop clutter  
- Paste commands into terminal before recording  
- Upload to OneDrive / YouTube (unlisted) and paste link in cover sheet  

---

## Pre-submission tests (run 24h before deadline)

```powershell
# Compose
docker compose up --build -d
curl http://localhost:5000/health

# Minikube core
minikube start --cni=calico
.\k8s\deploy.ps1
.\k8s\deploy-security-monitoring.ps1
kubectl get pods -n acme-todo

# OpenFaaS
.\serverless\openfaas\install-openfaas.ps1
kubectl port-forward -n openfaas svc/gateway 8080:8080
# deploy function per serverless/openfaas/README.md

# Edge
.\edge\setup-edge.ps1
curl http://localhost:8088
```

---

## Creating the submission archive (ZIP)

From the **parent folder** of the project (so paths are clean):

```powershell
# Exclude heavy/generated folders
Compress-Archive -Path "multi-tier-app" -DestinationPath "KhurramFarooqui_2325493_Portfolio.zip"
```

**Before zipping, delete or exclude:**

- `backend/node_modules/`
- `web/node_modules/`
- `.env` files (use `.env.example` only)
- `web/build/`
- Any local Docker volumes

**Include:**

- All source, Dockerfiles, `k8s/`, `docker-compose.yml`, scripts, `docs/` (logbook + report)
- `README.md` at repository root

**Optional:** Add `VIDEO_LINK.txt` in the zip root with your demonstration URL.

## Files to exclude from archive

- `node_modules/`  
- `.env` with real passwords  
- Large Docker volumes  
- `pgdata` volume data  

---

## Cover sheet text (template)

> **Cloud Technologies — Final Portfolio**  
> Student: Khurram Farooqui (2325493)  
> Project: ACMEInnovateNow To-Do Application Modernization  
> Repository: https://github.com/Khurram200/multi-tier-app  
> Video: [paste URL]  
> Date: [submission date]  

---

## Grading alignment (self-check)

| Criterion | Evidence |
|-----------|----------|
| Containerization best practices | Dockerfiles, compose, logbook Entry 2 |
| Kubernetes orchestration | `k8s/`, Entry 3 |
| Security | NetworkPolicy, RBAC, SECURITY.md, Entry 4 |
| Monitoring | Prometheus, Grafana, Entry 4 |
| Serverless | OpenFaaS todo-notify, Entry 5 |
| Edge computing | k3d edge-health, Entry 5 |
| Professional documentation | PROJECT_REPORT.md, logbook |
| Working demo | Video + README |

---

**Final action:** Submit before **29 May 2026** module deadline and keep a local backup copy.
