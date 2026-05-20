# Comprehensive Project Report

**ACMEInnovateNow — Cloud-Native Modernization of the To-Do Application**

| Field | Value |
|-------|--------|
| Student | Khurram Farooqui |
| Student number | 2325493 |
| Module | Cloud Technologies |
| Issue date | 29 April 2026 |
| Submission deadline | 29 May 2026 |
| Repository | https://github.com/Khurram200/multi-tier-app |

---

## 1. Executive summary

This project modernized a legacy-style three-tier To-Do web application into a **cloud-native system** that runs entirely on a local machine using open-source tooling: **Docker**, **Docker Compose**, **Minikube (Kubernetes)**, **OpenFaaS (serverless)**, **K3s via k3d (edge)**, **Prometheus**, and **Grafana**.

The work progressed through deliberate engineering phases: exploration, containerization, orchestration, security and monitoring, and advanced architectures. Each phase is documented in the **Technical Logbook** with commands, verification steps, and reflections.

**Key outcomes:**

- Application decomposed into **presentation**, **API**, and **data** tiers with clear boundaries  
- Reproducible deployment via **`docker compose up`** and **`kubectl apply`**  
- **NetworkPolicy** and **RBAC** reduce blast radius between tiers  
- **Prometheus/Grafana** provide observability of the API tier  
- **OpenFaaS** handles event-style validation workloads separately from long-running services  
- **K3s edge cluster** demonstrates deployment to a resource-constrained node  

---

## 2. Problem statement

ACMEInnovateNow’s monolithic To-Do application could not scale components independently, was difficult to deploy consistently across environments, and lacked modern security and observability practices. The business required a path to cloud-native operations without immediately depending on public cloud spend—local parity was essential for development and assessment.

---

## 3. Solution architecture

### 3.1 Logical architecture

```
                    ┌─────────────────────────────────────────┐
                    │           User browser (host)            │
                    └───────────────┬─────────────────────────┘
                                    │ HTTP
          ┌─────────────────────────┼─────────────────────────┐
          │ Minikube / Compose       │                         │
          │  ┌──────────┐   ┌───────▼──────┐   ┌──────────┐ │
          │  │ frontend │   │   backend    │   │ postgres │ │
          │  │  React   │──►│   Express    │──►│    DB    │ │
          │  └──────────┘   └───────┬──────┘   └──────────┘ │
          │                         │ optional webhook        │
          │                         ▼                         │
          │                  ┌─────────────┐                  │
          │                  │  OpenFaaS   │                  │
          │                  │ todo-notify │                  │
          │                  └─────────────┘                  │
          │  Prometheus ◄── scrape /metrics                   │
          │  Grafana ◄────── dashboards                         │
          └─────────────────────────────────────────────────────┘

          ┌──────────────── K3s edge (k3d) ────────────────┐
          │  edge-health (nginx, minimal resources)       │
          └───────────────────────────────────────────────┘
```

### 3.2 Technology choices

| Layer | Choice | Justification |
|-------|--------|---------------|
| Containers | Docker multi-stage | Smaller images, non-root user, cached builds |
| Local orchestration | Docker Compose | Fast inner loop for developers |
| Production-like orchestration | Minikube + kubectl | Declarative deploys, probes, secrets |
| Network isolation | Calico + NetworkPolicy | Enforce tier boundaries |
| Identity | ServiceAccounts + RBAC | Least privilege per workload |
| Metrics | Prometheus + prom-client | Industry-standard pull model |
| Visualization | Grafana | Dashboards for stakeholders |
| Serverless | OpenFaaS on K8s | Scale-to-zero style functions for events |
| Edge | k3d (K3s in Docker) | Lightweight cluster simulating edge sites |

---

## 4. Implementation summary by phase

### 4.1 Setup and exploration

- Installed Docker Desktop and validated daemon connectivity  
- Ran application **without containers** to understand dependencies (Node, Postgres, ports 3000/5000/5432)  
- Documented three-tier data flow in Technical Logbook Entry 1  

### 4.2 Foundational containerization

- Authored **multi-stage Dockerfiles** for backend and frontend with **`USER node`**  
- Created **`docker-compose.yml`** with health checks, named network `app-network`, and volume `pgdata`  
- Verified single-command startup: `docker compose up --build`  

### 4.3 Kubernetes orchestration

- Converted Compose services to **Deployments**, **Services**, **ConfigMaps**, **Secrets**, and **PVC** under namespace `acme-todo`  
- Deployed to **Minikube** with image builds in Minikube’s Docker daemon  
- Exposed UI/API via **NodePort**; configured `REACT_APP_API_URL` for browser access  

### 4.4 Security and monitoring

- **NetworkPolicy:** database accepts traffic only from backend; frontend pods cannot reach database port  
- **RBAC:** separate Roles per ServiceAccount; frontend cannot read Secrets  
- **Prometheus/Grafana:** backend exposes `/metrics`; dashboards show `http_requests_total`  

### 4.5 Advanced architectures

- **OpenFaaS:** deployed `todo-notify` function for async title validation; optional backend webhook on todo create  
- **Edge:** k3d cluster `acme-edge` runs lightweight `edge-health` service at `http://localhost:8088`  

---

## 5. Security posture

| Control | Implementation |
|---------|----------------|
| Secret storage | Kubernetes Secrets / Compose env (local only) |
| Network segmentation | NetworkPolicy per tier |
| Least privilege | RBAC scoped to namespace and resource names |
| Container hardening | Non-root, Alpine runtime, .dockerignore |
| Observability | Metrics without exposing admin interfaces publicly |

**Known local-dev limitations:** NodePort exposes services to host; plaintext secrets in local manifests acceptable for assessment only—not production pattern.

See [SECURITY.md](SECURITY.md).

---

## 6. Monitoring and operations

- **Health:** `GET /health` (DB connectivity)  
- **Metrics:** `GET /metrics` (Prometheus text format)  
- **Dashboards:** Grafana folder “ACME Todo”  
- **Runbooks:** README, k8s/README.md, monitoring/README.md  

---

## 7. Testing and verification

| Test | Method | Expected |
|------|--------|----------|
| Compose stack | `docker compose up` | All services healthy |
| CRUD API | Browser / curl | Todos persist |
| K8s pods | `kubectl get pods -n acme-todo` | Running / Ready |
| NetworkPolicy | `nc` from frontend pod to postgres | Blocked |
| RBAC | `kubectl auth can-i` | Frontend denied secrets |
| Prometheus | Targets UI | backend UP |
| OpenFaaS | `curl` POST to `/function/todo-notify` | JSON event response |
| Edge | `curl http://localhost:8088` | HTML status page |

---

## 8. Challenges and mitigations

| Challenge | Mitigation |
|-----------|------------|
| Windows port 5000 conflict | Map host port 5001 or free AirPlay Receiver |
| Postgres 18 volume path | Mount `pgdata` at `/var/lib/postgresql` |
| NetworkPolicy requires CNI | `minikube start --cni=calico` |
| Browser vs in-cluster API URL | NodePort + `REACT_APP_API_URL` with Minikube IP |
| CRA slow start in K8s | Extended readiness probes |

---

## 9. Conclusion

The project demonstrates a credible **local cloud-native pipeline** from legacy three-tier code to containerized, orchestrated, secured, observable, and partially serverless/edge-extended architecture. The same patterns transfer to managed Kubernetes (AKS, EKS, GKE) with replacement of Minikube/k3d by cloud clusters and sealed secrets / managed databases.

---

## 10. References

- Docker documentation: https://docs.docker.com  
- Kubernetes documentation: https://kubernetes.io/docs  
- Minikube: https://minikube.sigs.k8s.io  
- OpenFaaS: https://docs.openfaas.com  
- k3d / K3s: https://k3d.io , https://k3s.io  
- Prometheus: https://prometheus.io/docs  
- Grafana: https://grafana.com/docs  

---

## 11. Appendix — repository map

| Path | Contents |
|------|----------|
| `backend/`, `web/`, `db/` | Application source |
| `docker-compose.yml` | Compose orchestration |
| `k8s/` | Kubernetes manifests |
| `k8s/security/` | NetworkPolicy, RBAC |
| `k8s/monitoring/` | Prometheus, Grafana |
| `serverless/openfaas/` | OpenFaaS function |
| `edge/` | K3s edge simulation |
| `docs/TECHNICAL_LOGBOOK.md` | Phase-by-phase evidence |
| `docs/PORTFOLIO_SUBMISSION.md` | Submission checklist |
