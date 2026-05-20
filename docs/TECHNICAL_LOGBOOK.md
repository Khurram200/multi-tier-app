# Technical Logbook — ACMEInnovateNow Cloud Modernization

**Student:** Khurram Farooqui  
**Student number:** 2325493  
**Course:** Cloud Technologies  
**Project:** Legacy To-Do Application → Cloud-Native System  
**Repository:** `multi-tier-app`  
**Issue date:** 29 April 2026  
**Submission deadline:** 29 May 2026  
**Schedule:** See `docs/PROJECT_PLAN.md`

---

## Entry 1 — Setup and Initial Exploration

**Date:** _[YYYY-MM-DD]_  
**Phase:** Setup and Initial Exploration  
**Objective:** Prepare the local environment, learn Docker basics, run the app without containers, and document architecture observations.

---

### 1. Docker Desktop installation and verification

#### Actions taken

| Step | Command / action | Result |
|------|------------------|--------|
| Install Docker Desktop | Download from [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/) | _[Done / In progress]_ |
| Start Docker Desktop | Open app; wait until status shows **Engine running** | _[Pass / Fail]_ |
| Verify client | `docker version` | Client: _[version]_ |
| Verify daemon | `docker version` (Server section) | Server: _[version or "cannot connect"]_ |
| Smoke test | `docker run hello-world` | _[Pass / Fail]_ |

#### Notes

- On Windows, Docker Desktop uses the **Linux engine** (`desktop-linux` context). The daemon must be running before `docker compose` or `docker build` work.
- If you see `failed to connect to the docker API at npipe://...dockerDesktopLinuxEngine`, Docker Desktop is **not running** — start it from the system tray and retry.
- Optional: enable **WSL 2** backend (recommended on Windows 11).

**Verification checklist**

- [ ] Docker Desktop icon shows **Running**
- [ ] `docker version` shows both **Client** and **Server**
- [ ] `docker ps` runs without error
- [ ] `docker compose version` runs without error

---

### 2. Introductory Docker tutorials (self-study)

Complete the tutorials from your self-study plan. Record what you practiced and one takeaway per topic.

| Topic | Commands practiced | Key takeaway |
|-------|-------------------|--------------|
| Images & containers | `docker pull`, `docker run`, `docker ps`, `docker stop`, `docker rm` | _[e.g. Containers are ephemeral instances of images]_ |
| Dockerfile | `docker build -t <name> .`, `docker images` | _[e.g. Dockerfile defines reproducible image builds]_ |
| Volumes | `docker volume ls`, `-v` mount | _[e.g. Volumes persist data beyond container lifetime]_ |
| Networking | `docker network ls`, container DNS names | _[e.g. Compose services resolve each other by service name]_ |
| Compose | `docker compose up`, `down`, `build`, `logs` | _[e.g. Compose orchestrates multi-container apps from YAML]_ |

**Reflection:** How does Docker differ from running Node and Postgres directly on the host?

_[Your answer: isolation, consistent environments, dependency packaging, etc.]_

---

### 3. Application run — without containers (bare metal / local)

#### Prerequisites installed

| Tool | Version (record yours) | Purpose |
|------|------------------------|---------|
| Node.js | _[e.g. 22.x]_ | Backend + frontend runtime |
| npm | _[e.g. 11.x]_ | Package manager |
| PostgreSQL | _[e.g. 16+]_ | Database (local install or portable)_ |

#### Database setup (local Postgres)

1. Ensure PostgreSQL is running on port **5432**.
2. Create database and user (adjust password to match `backend/.env`):

```sql
CREATE DATABASE todo;
-- If using default postgres user, ensure password matches backend/.env
```

3. Apply schema and seed data:

```powershell
psql -U postgres -d todo -f db/init.sql
```

#### Backend (Terminal 1)

```powershell
cd backend
npm install
# Ensure .env exists (see backend/.env.example)
npm start
```

Expected log: `Backend running on port 5000`

Test API: open `http://localhost:5000/api/todos` in browser or run:

```powershell
curl http://localhost:5000/api/todos
```

#### Frontend (Terminal 2)

```powershell
cd web
npm install
npm start
```

Expected: browser opens `http://localhost:3000` (CRA dev server).

Default API URL in `web/src/App.js`: `http://localhost:5000/api/todos` — no extra env needed for local non-container run.

#### Run log

| Component | Started? | URL / port | Issues |
|-----------|----------|------------|--------|
| PostgreSQL | _[Y/N]_ | localhost:5432 | _[none / describe]_ |
| Backend API | _[Y/N]_ | http://localhost:5000 | _[none / describe]_ |
| React UI | _[Y/N]_ | http://localhost:3000 | _[none / describe]_ |
| End-to-end (add/list todo) | _[Y/N]_ | — | _[none / describe]_ |

---

### 4. Initial architecture analysis (pre-containerization view)

#### Application purpose

A **To-Do List** web application: users view, add, edit, complete, and delete tasks. Data is stored in **PostgreSQL**; the UI talks to a **REST API**.

#### Logical components

```
┌─────────────────┐     HTTP (JSON)      ┌─────────────────┐     SQL          ┌─────────────────┐
│  Presentation   │ ──────────────────► │   Application   │ ───────────────► │      Data       │
│  React (web/)   │   /api/todos        │  Express        │   todos table    │  PostgreSQL     │
│  Port 3000      │                     │  (backend/)     │                  │  Port 5432      │
│                 │                     │  Port 5000      │                  │  db/init.sql    │
└─────────────────┘                     └─────────────────┘                  └─────────────────┘
```

#### Monolith vs current structure

| Aspect | Classic monolith | This boilerplate |
|--------|------------------|------------------|
| Deployment unit | Single process / WAR | **Three** separate processes (UI, API, DB) |
| Scaling | Scale entire app together | Can scale API and UI independently later |
| Data access | Often embedded ORM in same app | API owns DB access via `pg` pool |
| Frontend | Server-rendered or bundled in same repo | **SPA** (React) calling REST API |

**Initial thought:** The codebase is already a **logical three-tier architecture** (presentation, business/API, data), but it may still be **operationally monolithic** if deployed as one VM without containers. Containerization and Kubernetes will formalize boundaries, networking, and operations.

#### Key files reviewed

| Path | Role |
|------|------|
| `web/src/App.js` | UI; axios calls to `REACT_APP_API_URL` or `localhost:5000` |
| `backend/server.js` | REST routes: GET/POST/PUT/DELETE `/api/todos` |
| `backend/.env` | DB connection + `PORT` (must not commit real secrets to git) |
| `db/init.sql` | Schema + seed todos |
| `docker-compose.yml` | _(explored in later phase)_ Multi-service orchestration |

#### API surface (backend)

| Method | Path | Behavior |
|--------|------|----------|
| GET | `/api/todos` | List all todos |
| POST | `/api/todos` | Create todo (`title` in body) |
| PUT | `/api/todos/:id` | Update title / completed |
| DELETE | `/api/todos/:id` | Remove todo |

#### Risks / observations for later phases

- Passwords in compose/env files → move to **secrets** in K8s.
- No `/health` endpoint yet → needed for orchestrator probes.
- CORS defaults to `*` → tighten for production.
- Frontend dev server in Docker is fine for dev; production should serve **static build** (nginx).

---

### 5. Reflection and next steps

**What went well**

_[e.g. All three tiers ran locally; understood request flow from browser → API → DB]_

**Challenges**

_[e.g. Postgres password mismatch, port 5000 in use on Windows, Docker daemon not started]_

**Next phase preview**

- Containerize each tier with Dockerfiles (already started in repo).
- Orchestrate with `docker compose`, then **local Kubernetes**.
- Add security, monitoring, and serverless components per project rubric.

---

## Entry 2 — Foundational Containerization

**Date:** _[YYYY-MM-DD]_  
**Phase:** Foundational Containerization  
**Objective:** Containerize web, backend, and database; orchestrate with Docker Compose; single `docker compose up` workflow.

---

### 1. Dockerfiles (multi-stage, non-root)

| Service | File | Builder stage | Runtime stage | Non-root |
|---------|------|---------------|---------------|----------|
| Backend | `backend/Dockerfile` | `node:20`, `npm ci` | `node:20-alpine`, `npm prune --production` | `USER node` |
| Frontend | `web/Dockerfile` | `node:20`, `npm ci` | `node:20-alpine` | `USER node` |

**Why multi-stage?** Dependencies are installed in a full image; only `node_modules` and app code are copied to Alpine, keeping the runtime image smaller and reducing attack surface.

**Why non-root?** Containers should not run as UID 0 in production; the official Node image provides the `node` user after `chown -R node:node /app`.

---

### 2. docker-compose.yml

| Requirement | Implementation |
|-------------|----------------|
| Three services | `database`, `backend`, `frontend` |
| Network | `app-network` (bridge); all services attached |
| DB persistence | Named volume `pgdata` → `/var/lib/postgresql` (Postgres 18+ layout) |
| Service discovery | `DB_HOST=database` (DNS name on compose network) |
| Startup order | `depends_on` + `condition: service_healthy` for database → backend → frontend |
| Init data | `./db/init.sql` mounted to `/docker-entrypoint-initdb.d/` |

---

### 3. Verification (`docker compose up --build`)

| Check | Command / URL | Result |
|-------|---------------|--------|
| Build images | `docker compose build` | _[Pass / Fail]_ |
| Start stack | `docker compose up --build` | _[Pass / Fail]_ |
| Database healthy | `docker compose ps` | _[healthy]_ |
| Backend health | http://localhost:5000/health | _[JSON status ok]_ |
| API | http://localhost:5000/api/todos | _[JSON array]_ |
| UI | http://localhost:3000 | _[todos visible]_ |

**Screenshot / log evidence:** _[attach or note path]_

---

### 4. Reflection

**Best practices applied:** _[multi-stage, .dockerignore, healthchecks, named volume, explicit network]_

**Issues encountered:** _[e.g. port 5000 in use, Postgres volume path, npm ci lockfile]_

**Next phase:** Local Kubernetes manifests (`k8s/`).

---

## Entry 3 — Orchestration with Kubernetes (Minikube)

**Date:** _[YYYY-MM-DD]_  
**Phase:** Orchestration with Kubernetes  
**Objective:** Deploy containerized tiers to Minikube; verify in-cluster communication and browser access.

---

### 1. Minikube and kubectl setup

| Step | Command | Result |
|------|---------|--------|
| Start cluster | `minikube start --driver=docker` | _[Pass / Fail]_ |
| Verify API | `kubectl cluster-info` | _[Pass / Fail]_ |
| Verify node | `kubectl get nodes` | _[Ready]_ |
| Configure Docker | `minikube docker-env --shell powershell \| Invoke-Expression` | _[Pass / Fail]_ |

---

### 2. Kubernetes manifests (Compose → K8s)

| Compose service | K8s resources | Notes |
|-----------------|---------------|-------|
| `database` | `postgres` Deployment + Service + PVC | `DB_HOST=postgres`; volume `/var/lib/postgresql` |
| `backend` | `backend` Deployment + NodePort Service | Image `todo-backend:latest`; probes on `/health` |
| `frontend` | `frontend` Deployment + NodePort Service | Image `todo-frontend:latest`; `REACT_APP_API_URL` via ConfigMap |
| env / secrets | `app-config`, `app-secrets` | Passwords in Secret; non-secrets in ConfigMap |
| network | Namespace `acme-todo` | Cluster DNS between Services |

**Manifest path:** `k8s/*.yaml`  
**Deploy script:** `k8s/deploy.ps1`

---

### 3. Deploy and verify

| Check | Command / action | Result |
|-------|------------------|--------|
| Build images in Minikube | `docker build -t todo-backend:latest ./backend` (after `docker-env`) | _[Pass / Fail]_ |
| Apply manifests | `.\k8s\deploy.ps1` | _[Pass / Fail]_ |
| All pods Running | `kubectl get pods -n acme-todo` | _[3/3 Running]_ |
| Backend → DB | `kubectl logs deploy/backend -n acme-todo` | _[no connection errors]_ |
| API (NodePort) | `minikube service backend -n acme-todo --url` + `/api/todos` | _[JSON]_ |
| UI (NodePort) | `minikube service frontend -n acme-todo --url` | _[todos load]_ |

**Minikube IP:** _[record `minikube ip`]_  
**Frontend URL:** _[record URL]_  
**Backend API URL:** _[http://IP:30050/api/todos]_

---

### 4. Reflection

**Compose vs Kubernetes:** _[orchestration, self-healing, probes, declarative manifests]_

**Issues:** _[ImagePullBackOff, frontend API URL, postgres PVC, timing]_

**Next phase:** Security hardening, monitoring, serverless.

---

## Entry 4 — Security and Monitoring

**Date:** _[YYYY-MM-DD]_  
**Phase:** Security and Monitoring  
**Objective:** NetworkPolicy tier isolation, RBAC least privilege, Prometheus + Grafana on Minikube.

---

### 1. NetworkPolicy

| Policy | Purpose | Verified |
|--------|---------|----------|
| `postgres-network-policy` | DB ingress only from backend | _[Y/N]_ |
| `frontend-network-policy` | No egress to postgres (DNS only) | _[Y/N]_ |
| `backend-network-policy` | API + metrics ingress; egress to DB | _[Y/N]_ |

**CNI used:** _[Calico — `minikube start --cni=calico`]_

**Test frontend → postgres blocked:**

```powershell
kubectl exec -n acme-todo deploy/frontend -- sh -c "nc -zv postgres 5432 2>&1 || echo BLOCKED"
```

Result: _[record output]_

---

### 2. RBAC (ServiceAccounts, Roles, RoleBindings)

| ServiceAccount | Role | Can read app-secrets? |
|----------------|------|------------------------|
| `frontend-sa` | `frontend-app-role` | _[no]_ |
| `backend-sa` | `backend-app-role` | _[yes]_ |
| `postgres-sa` | `postgres-app-role` | _[no]_ |
| `prometheus-sa` | `prometheus-scrape-role` | _[N/A — pods only]_ |

```powershell
kubectl auth can-i get secrets/app-secrets --as=system:serviceaccount:acme-todo:frontend-sa -n acme-todo
kubectl auth can-i get secrets/app-secrets --as=system:serviceaccount:acme-todo:backend-sa -n acme-todo
```

---

### 3. Prometheus & Grafana

| Component | URL | Notes |
|-----------|-----|-------|
| Prometheus | `minikube service prometheus -n acme-todo --url` | Targets: backend **UP** |
| Grafana | `minikube service grafana -n acme-todo --url` | admin / admin |
| Dashboard | ACME Todo - Backend HTTP | `http_requests_total` |

**Sample metric after using app:** _[screenshot or query result]_

---

### 4. Reflection

**Security trade-offs:** _[NodePort still exposes API to host; policies enforce pod-to-pod rules]_

**Monitoring learnings:** _[RED metrics, scrape config, Grafana datasource]_

---

## Entry 5 — Advanced architectures & final submission

**Date:** _[YYYY-MM-DD]_  
**Phase:** Serverless, edge computing, portfolio finalization  
**Objective:** OpenFaaS event function, K3s edge node, finalize report and demonstration video.

---

### 1. OpenFaaS serverless function

| Step | Action | Result |
|------|--------|--------|
| Install OpenFaaS | `.\serverless\openfaas\install-openfaas.ps1` | _[Pass / Fail]_ |
| Port-forward gateway | `kubectl port-forward -n openfaas svc/gateway 8080:8080` | _[Pass / Fail]_ |
| Build & deploy | `faas-cli build/deploy -f todo-notify.yml` | _[Pass / Fail]_ |
| Invoke function | POST `/function/todo-notify` with JSON `title` | _[Pass / Fail]_ |
| Event from API | Create todo in UI; check backend logs for webhook | _[optional]_ |

**Function purpose:** `todo-notify` validates todo titles asynchronously (event-driven), separate from long-running CRUD Deployment.

**Evidence:** _[curl output, OpenFaaS UI screenshot]_

---

### 2. Edge computing (K3s in Docker via k3d)

| Step | Action | Result |
|------|--------|--------|
| Install k3d | _[choco / winget]_ | _[version]_ |
| Create cluster | `.\edge\setup-edge.ps1` | _[Pass / Fail]_ |
| Deploy edge-health | nginx alpine, 16–32Mi limits | _[Running]_ |
| Access service | http://localhost:8088 | _[HTML page]_ |

**Rationale:** Full stack on Minikube = cloud/core; K3s edge cluster = constrained remote site with lightweight service only.

**Evidence:** _[kubectl get pods -n edge, curl screenshot]_

---

### 3. Final deliverables completed

| Deliverable | File | Complete |
|-------------|------|----------|
| Technical Logbook | `docs/TECHNICAL_LOGBOOK.md` | _[Y/N]_ |
| Project Report | `docs/PROJECT_REPORT.md` | _[Y/N]_ |
| Portfolio checklist | `docs/PORTFOLIO_SUBMISSION.md` | _[Y/N]_ |
| Demonstration video | _[URL]_ | _[Y/N]_ |
| Repository README | `README.md` | _[Y/N]_ |

---

### 4. Final reflection (executive summary for portfolio)

**Problem solved:** _[monolith → scalable local cloud-native system]_

**Strongest engineering decisions:** _[e.g. tier split, NetworkPolicy, OpenFaaS for events only]_

**What I would do next in production:** _[managed K8s, sealed secrets, ingress TLS, CI/CD, production frontend build]_

**Submission date:** _[DD/MM/2026]_

---

## Appendix — Quick reference commands

```powershell
# Docker health
docker version
docker ps
docker compose ps

# Local (no containers) — three terminals
# 1: Postgres running + psql -f db/init.sql
# 2: cd backend && npm start
# 3: cd web && npm start

# Containerized
docker compose up --build

# Kubernetes (Minikube)
minikube start
.\k8s\deploy.ps1
kubectl get all -n acme-todo
minikube service frontend -n acme-todo --url

# Security & monitoring
minikube start --cni=calico
.\k8s\deploy-security-monitoring.ps1
minikube service prometheus -n acme-todo --url
minikube service grafana -n acme-todo --url

# OpenFaaS serverless
.\serverless\openfaas\install-openfaas.ps1
kubectl port-forward -n openfaas svc/gateway 8080:8080
curl -X POST http://127.0.0.1:8080/function/todo-notify -H "Content-Type: application/json" -d "{\"title\":\"Test\"}"

# Edge (K3s via k3d)
.\edge\setup-edge.ps1
curl http://localhost:8088
```
