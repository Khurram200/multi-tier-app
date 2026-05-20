# Cumulative Technical Logbook

**ACMEInnovateNow — Cloud-Native Modernization Project**


| Field                   | Value                                                                                        |
| ----------------------- | -------------------------------------------------------------------------------------------- |
| **Student**             | Khurram Farooqui                                                                             |
| **Student number**      | 2325493                                                                                      |
| **Module**              | Cloud Technologies                                                                           |
| **Issue date**          | 29 April 2026                                                                                |
| **Submission deadline** | 29 May 2026                                                                                  |
| **Repository**          | [https://github.com/Khurram200/multi-tier-app](https://github.com/Khurram200/multi-tier-app) |


---

## Document purpose

This logbook is a **single cumulative record** of the full project journey: what was built, **why** each decision was made, **what went wrong**, and **how** it was fixed. It supports the portfolio alongside the Comprehensive Project Report and demonstration video.

---

## Journey overview


| Phase | Focus                 | Primary artefacts                        |
| ----- | --------------------- | ---------------------------------------- |
| 1     | Setup & exploration   | Local run, architecture understanding    |
| 2     | Containerization      | Dockerfiles, `docker-compose.yml`        |
| 3     | Kubernetes            | `k8s/` manifests, Minikube deploy        |
| 4     | Security & monitoring | NetworkPolicy, RBAC, Prometheus, Grafana |
| 5     | Advanced & submission | OpenFaaS, K3s edge, GitHub, portfolio    |


```text
Legacy three-tier code
        │
        ▼
┌───────────────────┐
│ Docker Compose    │  ← reproducible local stack
└─────────┬─────────┘
          ▼
┌───────────────────┐
│ Minikube (K8s)    │  ← declarative orchestration
└─────────┬─────────┘
          ▼
┌───────────────────┐
│ Security + metrics│  ← NetworkPolicy, RBAC, Prometheus
└─────────┬─────────┘
          ▼
┌───────────────────┐
│ Serverless + edge │  ← OpenFaaS, k3d
└───────────────────┘
```

---

## Cross-cutting design rationale

### Why decompose into three tiers?

The application already separated **React (UI)**, **Express (API)**, and **PostgreSQL (data)** in code. The modernization goal was to make that separation **operational**: independent deploy units, scaling, and failure domains. A true monolith would couple UI rendering and SQL in one process; here the API is the only component that talks to the database, which simplifies security policy and future API consumers (mobile apps, partners).

### Why Docker before Kubernetes?

**Compose** offers the fastest feedback loop on a laptop (`docker compose up --build`). **Kubernetes** adds health probes, Secrets, and scheduling—closer to production—but more moving parts. The deliberate order was: prove containers work (Compose), then prove orchestration (Minikube).

### Why Minikube and not cloud first?

The brief required everything **runnable locally** without cloud cost. Minikube provides a real Kubernetes API on the developer machine. The same manifests could later apply to AKS/EKS/GKE with minimal changes (Ingress class, storage class, external secrets).

### Why OpenFaaS only for a small function?

Serverless fits **short, event-triggered** work (validation, notifications). Keeping CRUD on a long-running Deployment avoids cold starts, connection pooling issues with Postgres, and complex state management. `**todo-notify`** validates titles asynchronously—a clear teaching example of **when not to serverless the whole app**.

### Why K3s (k3d) for edge?

Edge sites are **resource-constrained**. Running full Postgres + React on every site is unrealistic. **k3d** runs K3s inside Docker to simulate an edge node; only **edge-health** (nginx, 16–32Mi limits) runs there, while the full stack stays on Minikube as the “core” cluster.

---

## Phase 1 — Setup and initial exploration

**Objective:** Prepare the environment, learn Docker fundamentals, run the app without containers, and document architecture.

### Task 1 — Docker Desktop installed and verified

- Installed **Docker Desktop** on Windows 10/11.
- Confirmed the daemon is running before any container work:

```powershell
docker version
docker info
docker run --rm hello-world
```

**Expected:** `docker version` shows both **Client** and **Server**; `hello-world` exits successfully.

### Task 2 — Introductory Docker tutorials (self-study)

Completed the module self-study topics and recorded the commands used:


| Topic               | Commands practised                                                   | Outcome                                            |
| ------------------- | -------------------------------------------------------------------- | -------------------------------------------------- |
| Images & containers | `docker pull`, `docker run`, `docker ps`, `docker stop`, `docker rm` | Understood image vs running container              |
| Dockerfile          | `docker build -t test .`, `docker images`                            | Linked Dockerfile instructions to image layers     |
| Volumes             | `docker volume ls`, named volume in later Compose work               | Data persistence separate from container lifecycle |
| Networking          | `docker network ls`, bridge network in Compose                       | Service DNS names (`database`, `backend`)          |
| Compose             | `docker compose up`, `docker compose down`, `docker compose logs`    | Multi-container stack as one manifest              |


### Task 3 — Clone boilerplate and run locally (no containers)

- Cloned the provided three-tier to-do boilerplate into `multi-tier-app` (local path; published copy: [GitHub](https://github.com/Khurram200/multi-tier-app)).
- Ran three **host processes** (not Docker) using `docs/SETUP_LOCAL_WITHOUT_DOCKER.md`:
  1. PostgreSQL + `db/init.sql` on port **5432**
  2. `backend` — `npm install` → `npm start` on port **5000**
  3. `web` — `npm install` → `npm start` on port **3000**
- Verified API: `http://localhost:5000/api/todos` returns JSON seed data.
- Verified UI: browser CRUD on `http://localhost:3000`.
- Mapped request flow: browser → `localhost:5000/api/todos` → Express → `pg` pool → `todos` table.

### Task 4 — Technical Logbook started

This Phase 1 section documents setup, tutorial learning, non-container run, and initial architecture notes (tables below).

### Design observations


| Topic              | Rationale                                                                              |
| ------------------ | -------------------------------------------------------------------------------------- |
| SPA + REST         | Frontend holds no business logic; API is the contract for all clients.                 |
| `db/init.sql`      | Schema and seed data versioned with code; same file used in Compose and K8s ConfigMap. |
| `.env` for backend | Twelve-factor style config; later moved to K8s Secrets for orchestrated deploys.       |


### Challenges and solutions


| Challenge                    | Cause                                      | Solution                                                                             |
| ---------------------------- | ------------------------------------------ | ------------------------------------------------------------------------------------ |
| Docker commands fail         | Daemon not started                         | Start Docker Desktop; confirm `docker version` shows **Server**                      |
| Backend cannot connect to DB | Wrong password in `.env` vs local Postgres | Align `DB_PASSWORD` with local Postgres user; use `backend/.env.example` as template |
| Confusion about “monolith”   | Three folders but one git repo             | Documented **logical** three-tier vs **operational** monolith (single VM deploy)     |


### Reflection

Running without containers clarified **dependencies and ports** (3000, 5000, 5432) before adding Docker networking. That made later debugging of `DB_HOST=database` vs `DB_HOST=postgres` easier because the underlying data flow was already understood.

---

## Phase 2 — Foundational containerization

**Objective:** Containerize web, backend, and database; orchestrate with Docker Compose; one-command startup.

### Implementation

**Dockerfiles (backend & web):**

- **Multi-stage build:** `node:20` builder → `node:20-alpine` runtime.
- `**npm ci`** in builder for reproducible installs.
- `**npm prune --production`** on runtime image.
- `**USER node`** after `chown -R node:node /app` (non-root).
- `**.dockerignore**` excludes `node_modules`, `.env`, `.git`.

`**docker-compose.yml`:**

- Services: `database`, `backend`, `frontend`.
- Network: `app-network` (bridge).
- Volume: `pgdata` at `/var/lib/postgresql` (required for **PostgreSQL 18+** image layout).
- Health checks: `pg_isready` on database; HTTP `/health` on backend via Node one-liner.
- `depends_on` with `condition: service_healthy` for startup ordering.

### Design rationale


| Decision                             | Why                                                                         |
| ------------------------------------ | --------------------------------------------------------------------------- |
| Multi-stage                          | Smaller images, fewer dev tools in production layer                         |
| Non-root                             | Reduces container escape impact                                             |
| Named volume                         | Data survives `docker compose down`                                         |
| Explicit bridge network              | Service DNS (`database`, `backend`) mirrors K8s service names               |
| CRA dev server in frontend container | Acceptable for assessment/dev; production would use `npm run build` + nginx |


### Challenges and solutions


| Challenge                            | Cause                                                      | Solution                                                                             |
| ------------------------------------ | ---------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Postgres container exits / unhealthy | Volume mounted at `/var/lib/postgresql/data` on PG 18      | Changed mount to `/var/lib/postgresql` per official image docs                       |
| `DB_PASSWORD` mismatch               | Compose had `1234`, Postgres image had `dataserver`        | Unified password to `**dataserver`** in compose and backend env                      |
| Port **5000** bind error on Windows  | AirPlay / other service uses 5000                          | Map `**5001:5000`** and set `REACT_APP_API_URL` to `http://localhost:5001/api/todos` |
| `npm ci` fails in web image          | `package-lock.json` out of sync with strict npm in Node 20 | Ran `npm install` locally; added `overrides` for `yaml` where needed                 |
| Empty `dockerfile` vs `Dockerfile`   | Case sensitivity                                           | Standardized on `**Dockerfile`**; removed empty lowercase files                      |


### Verification

Successful run: `docker compose up --build` → database **healthy**, backend log `Backend running on port 5000`, frontend **Compiled successfully**, UI at [http://localhost:3000](http://localhost:3000) with working CRUD.

---

## Phase 3 — Orchestration with Kubernetes (Minikube)

**Objective:** Convert Compose topology to manifests; deploy on Minikube; verify in-cluster and browser access.

### Implementation


| Compose    | Kubernetes (`namespace: acme-todo`)                              |
| ---------- | ---------------------------------------------------------------- |
| `database` | `postgres` Deployment + ClusterIP Service + PVC                  |
| `backend`  | `backend` Deployment + NodePort **30050**                        |
| `frontend` | `frontend` Deployment + NodePort **30030**                       |
| env vars   | ConfigMap `app-config`                                           |
| passwords  | Secret `app-secrets`                                             |
| init SQL   | ConfigMap key `init.sql` mounted to `docker-entrypoint-initdb.d` |


**Deploy automation:** `k8s/deploy.ps1` builds `todo-backend:latest` and `todo-frontend:latest` inside Minikube’s Docker (`imagePullPolicy: Never`), applies manifests in order, patches `REACT_APP_API_URL` with `minikube ip`.

### Design rationale


| Decision                        | Why                                                                     |
| ------------------------------- | ----------------------------------------------------------------------- |
| Namespace per app               | Isolation for RBAC and NetworkPolicy scope                              |
| NodePort for UI/API             | Browser runs on **host**; must reach Minikube IP, not cluster DNS names |
| ClusterIP for Postgres          | Database not exposed outside cluster                                    |
| Readiness/liveness on `/health` | Scheduler only routes traffic when DB connection works                  |
| Scripts vs only YAML            | Repeatable deploy for demos and assessment                              |


### Challenges and solutions


| Challenge               | Cause                                          | Solution                                                |
| ----------------------- | ---------------------------------------------- | ------------------------------------------------------- |
| `ImagePullBackOff`      | Images built on host Docker, not Minikube’s    | `minikube docker-env                                    |
| UI loads, todos empty   | `REACT_APP_API_URL` pointed to wrong host/port | Patch ConfigMap: `http://<minikube-ip>:30050/api/todos` |
| Frontend pod slow Ready | CRA compile time                               | Extended readiness `initialDelaySeconds` (30s+)         |
| DB pod pending          | Storage provisioner                            | `minikube addons enable storage-provisioner`            |
| Same PG 18 volume issue | Legacy path in manifest                        | PVC mount `/var/lib/postgresql`                         |


### Compose vs Kubernetes (reflection)

Compose is ideal for **developer velocity**. Kubernetes adds **self-healing**, declarative desired state, and primitives (Secrets, probes) that match production. The extra YAML complexity is justified when teaching **operations**, not just packaging.

---

## Phase 4 — Security and monitoring

**Objective:** NetworkPolicy isolation, RBAC least privilege, Prometheus + Grafana for pod/application metrics.

### Security implementation

**NetworkPolicy (requires Calico CNI):**

- **Postgres:** ingress only from pods `app: backend` on port 5432.
- **Frontend:** egress to **backend:5000** and DNS only → **cannot** reach postgres:5432 from the frontend pod (browser also uses host NodePort to API).
- **Backend:** ingress on 5000 (API + metrics); egress to postgres + DNS.
- **Prometheus/Grafana:** separate policies for scrape and UI paths.

**RBAC:**


| ServiceAccount  | Role (least privilege)                                  |
| --------------- | ------------------------------------------------------- |
| `frontend-sa`   | `get` ConfigMap `app-config` only                       |
| `backend-sa`    | `get` ConfigMap + Secret `app-secrets`                  |
| `postgres-sa`   | `get` PVC `postgres-pvc` only                           |
| `prometheus-sa` | `get/list/watch` pods, services, endpoints in namespace |


### Monitoring implementation

- Added `**prom-client`** to backend: `http_requests_total`, default process metrics.
- Exposed `**GET /metrics`** for Prometheus scrape.
- Deployed **Prometheus** (ConfigMap scrape config) and **Grafana** (provisioned Prometheus datasource + **ACME Todo - Backend HTTP** dashboard).
- NodePorts: Prometheus **30090**, Grafana **30300**.

### Design rationale


| Decision                     | Why                                                                 |
| ---------------------------- | ------------------------------------------------------------------- |
| NetworkPolicy                | Enforces “frontend cannot talk to DB” at pod network layer          |
| Named RBAC resources         | Demonstrates principle of least privilege per tier                  |
| Pull metrics                 | Prometheus model fits Kubernetes; no agent in app beyond `/metrics` |
| Local Grafana admin/password | Assessment only; would use SSO/secrets manager in production        |


### Challenges and solutions


| Challenge                            | Cause                                | Solution                                                 |
| ------------------------------------ | ------------------------------------ | -------------------------------------------------------- |
| NetworkPolicy has no effect          | Default Minikube CNI may not enforce | `minikube start --cni=calico`                            |
| Healthcheck `wget` missing in Alpine | Minimal node image                   | Use `node -e` HTTP check or httpGet probes in Deployment |
| Frontend blocked from DB test        | `nc` not in alpine image             | Use `sh` + `nc` if present, or document expected timeout |
| Metrics not in Grafana               | Wrong datasource UID                 | Provision datasource with `uid: prometheus` in ConfigMap |


---

## Phase 5 — Advanced architectures and final submission

**Objective:** OpenFaaS serverless function, K3s edge simulation, GitHub repository, portfolio deliverables.

### OpenFaaS — `todo-notify`

- **Function:** HTTP POST accepts `{ "title": "..." }`; validates length; returns `todo-notify-accepted` or `todo-notify-rejected` JSON events.
- **Deploy:** `serverless/openfaas/todo-notify.yml`, custom Dockerfile with `of-watchdog`.
- **Optional integration:** Backend `POST /api/todos` fires async webhook to `OPENFAAS_TODO_NOTIFY_URL`.

**Rationale:** Demonstrates **event-driven** processing without moving stateful CRUD off Kubernetes.

### Edge — K3s via k3d

- Cluster: `acme-edge` via `k3d cluster create`, port **8088** → loadbalancer.
- Workload: **edge-health** (nginx:alpine, 16–32Mi memory limits).
- **Rationale:** Core stack on Minikube; edge site runs only lightweight status endpoint.

### GitHub repository

- Pushed full IaC and docs to: **[https://github.com/Khurram200/multi-tier-app](https://github.com/Khurram200/multi-tier-app)**
- Commit `851eda7`: 52 files; `.env` excluded via `.gitignore`; `README.md` with deployment instructions.

### Portfolio deliverables


| Component                     | Location                                                                                     |
| ----------------------------- | -------------------------------------------------------------------------------------------- |
| Git repository (IaC + README) | [https://github.com/Khurram200/multi-tier-app](https://github.com/Khurram200/multi-tier-app) |
| Cumulative Technical Logbook  | `docs/TECHNICAL_LOGBOOK.md` + `ACMEInnovateNow-Portfolio/Technical-Logbook.md`               |
|                               |                                                                                              |
|                               |                                                                                              |


---

## Master table — challenges and solutions


| #   | Phase      | Challenge                     | Solution                               |
| --- | ---------- | ----------------------------- | -------------------------------------- |
| 1   | Setup      | Docker daemon not running     | Start Docker Desktop                   |
| 2   | Setup      | DB auth failure locally       | Align `.env` with Postgres password    |
| 3   | Compose    | Postgres 18 volume path       | Mount `pgdata` → `/var/lib/postgresql` |
| 4   | Compose    | Password mismatch compose/DB  | Single password `dataserver`           |
| 5   | Compose    | Port 5000 in use (Windows)    | Host map 5001 + update API URL         |
| 6   | Compose    | `npm ci` lockfile drift (web) | Regenerate lockfile / overrides        |
| 7   | K8s        | ImagePullBackOff              | Build inside Minikube Docker           |
| 8   | K8s        | Browser cannot reach API      | NodePort + Minikube IP in ConfigMap    |
| 9   | Security   | Policies not enforced         | Calico CNI                             |
| 10  | Monitoring | Alpine lacks wget             | httpGet / node probes                  |
| 11  | Git        | No `.git` initially           | `git init`, push to `origin/main`      |


---

## API and observability reference


| Endpoint         | Method     | Purpose                      |
| ---------------- | ---------- | ---------------------------- |
| `/api/todos`     | GET/POST   | List / create todos          |
| `/api/todos/:id` | PUT/DELETE | Update / delete              |
| `/health`        | GET        | Liveness/readiness (DB ping) |
| `/metrics`       | GET        | Prometheus scrape            |


---

## Final reflection

### What was achieved

The legacy-style To-Do application was transformed into a **documented, repeatable, cloud-native system** runnable entirely on a local machine: containerized tiers, Kubernetes orchestration, network and identity controls, metrics stack, serverless extension, and edge simulation—backed by a public Git repository and written evidence of engineering decisions.

### Strongest decisions

1. **Phased delivery** (Compose → K8s → security → advanced) reduced risk and made debugging tractable.
2. **NetworkPolicy** on postgres enforcing backend-only access—a concrete security story for assessors.
3. **Keeping CRUD on Deployments** and using OpenFaaS only for validation events—shows appropriate serverless scope.
4. **Cumulative documentation** (this logbook + report) separate from code so design intent is auditable.

### What I would improve for production

- TLS Ingress (cert-manager), no NodePort for public APIs  
- Sealed Secrets / external secret store; remove passwords from YAML  
- Production frontend: static build + nginx, not CRA dev server in container  
- CI/CD pipeline: build, scan images (Trivy), deploy to managed K8s  
- Managed PostgreSQL (RDS/Cloud SQL) with backups  
- HPA on backend based on `http_requests_total` rate

### Lessons learned

Technical skills gained: multi-stage Docker builds, Compose health graphs, Kubernetes primitives, Calico policies, RBAC debugging (`kubectl auth can-i`), Prometheus scrape config, and OpenFaaS packaging. Equally important was learning to **justify** when *not* to use a technology (full serverless monolith, exposing postgres externally).

---

## Appendix — command reference

```powershell
# Docker Compose
docker compose up --build
docker compose ps
curl http://localhost:5000/health

# Minikube
minikube start --driver=docker --cni=calico
.\k8s\deploy.ps1
.\k8s\deploy-security-monitoring.ps1
kubectl get pods -n acme-todo
minikube service frontend -n acme-todo --url

# Security checks
kubectl auth can-i get secrets/app-secrets --as=system:serviceaccount:acme-todo:frontend-sa -n acme-todo
kubectl exec -n acme-todo deploy/frontend -- sh -c "nc -zv postgres 5432 2>&1 || echo BLOCKED"

# Monitoring
minikube service prometheus -n acme-todo --url
minikube service grafana -n acme-todo --url

# OpenFaaS
.\serverless\openfaas\install-openfaas.ps1
kubectl port-forward -n openfaas svc/gateway 8080:8080

# Edge
.\edge\setup-edge.ps1
curl http://localhost:8088

# Repository
git clone https://github.com/Khurram200/multi-tier-app.git
```

---

**End of Cumulative Technical Logbook**

*Khurram Farooqui · 2325493 · Cloud Technologies · Submission May 2026*