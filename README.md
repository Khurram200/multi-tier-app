# ACMEInnovateNow — Cloud-Native To-Do Application

| | |
|---|---|
| **Student** | Khurram Farooqui |
| **Student number** | 2325493 |
| **Module** | Cloud Technologies |
| **Project** | Legacy application modernization (monolith → cloud-native) |

Production-style **three-tier** application (React, Express, PostgreSQL) packaged with **Docker**, orchestrated with **Docker Compose** and **Kubernetes (Minikube)**, hardened with **NetworkPolicy/RBAC**, observed with **Prometheus/Grafana**, extended with **OpenFaaS** serverless and a **K3s edge** simulation.

---

## Repository structure (infrastructure-as-code)

```
multi-tier-app/
├── README.md                 # This file — deployment instructions
├── docker-compose.yml        # Compose orchestration (3 services + network + volume)
├── backend/
│   ├── Dockerfile            # Multi-stage API image
│   ├── .dockerignore
│   ├── server.js             # REST API, /health, /metrics
│   └── package.json
├── web/
│   ├── Dockerfile            # Multi-stage frontend image
│   ├── .dockerignore
│   └── src/                  # React application
├── db/
│   └── init.sql              # Schema + seed data
├── k8s/                      # Kubernetes manifests (Minikube)
│   ├── namespace.yaml
│   ├── secret.yaml
│   ├── configmap.yaml
│   ├── postgres-pvc.yaml
│   ├── postgres.yaml         # Deployment + Service
│   ├── backend.yaml
│   ├── frontend.yaml
│   ├── deploy.ps1
│   ├── deploy-security-monitoring.ps1
│   ├── security/             # NetworkPolicy, RBAC, ServiceAccounts
│   └── monitoring/           # Prometheus, Grafana
├── serverless/openfaas/      # OpenFaaS function + install scripts
├── edge/                     # K3s edge cluster (k3d) + lightweight service
└── docs/                     # Logbook, project report, portfolio checklist
```

---

## Prerequisites

| Tool | Purpose | Verify |
|------|---------|--------|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Compose & image builds | `docker version` (Client **and** Server) |
| [Node.js](https://nodejs.org/) 18+ | Optional local run without containers | `node --version` |
| [Minikube](https://minikube.sigs.k8s.io/) | Local Kubernetes | `minikube version` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | Cluster CLI | `kubectl version --client` |
| [k3d](https://k3d.io/) | K3s in Docker (edge task) | `k3d version` |
| [arkade](https://github.com/alexellis/arkade) or Helm | OpenFaaS install (optional) | `arkade version` |

**Windows note:** If port **5000** is in use, map backend to **5001** in `docker-compose.yml` (see [Troubleshooting](#troubleshooting)).

---

## Quick start — Docker Compose (recommended first)

Single command starts database, API, and UI.

```powershell
git clone https://github.com/Khurram200/multi-tier-app.git
cd multi-tier-app
docker compose up --build
```

**Repository:** https://github.com/Khurram200/multi-tier-app

| Service | URL |
|---------|-----|
| Web UI | http://localhost:3000 |
| API | http://localhost:5000/api/todos |
| Health | http://localhost:5000/health |
| Metrics | http://localhost:5000/metrics |

Stop:

```powershell
docker compose down
```

Fresh database:

```powershell
docker compose down -v
```

---

## Deployment — Kubernetes (Minikube)

### 1. Start cluster

NetworkPolicy requires a compatible CNI:

```powershell
minikube start --driver=docker --cpus=4 --memory=6144 --cni=calico
kubectl cluster-info
```

### 2. Deploy application

```powershell
cd multi-tier-app
.\k8s\deploy.ps1
```

### 3. Security and monitoring

```powershell
.\k8s\deploy-security-monitoring.ps1
```

### 4. Access services

```powershell
kubectl get pods -n acme-todo
minikube service frontend -n acme-todo --url
minikube service backend -n acme-todo --url
minikube service prometheus -n acme-todo --url
minikube service grafana -n acme-todo --url
```

Grafana default login (local only): `admin` / `admin`

Detailed steps: [k8s/README.md](k8s/README.md) · [k8s/security/README.md](k8s/security/README.md) · [k8s/monitoring/README.md](k8s/monitoring/README.md)

---

## Deployment — OpenFaaS (serverless)

```powershell
.\serverless\openfaas\install-openfaas.ps1
kubectl port-forward -n openfaas svc/gateway 8080:8080
```

Build and deploy function (separate terminal, Minikube Docker):

```powershell
cd serverless\openfaas
minikube docker-env --shell powershell | Invoke-Expression
faas-cli build -f todo-notify.yml
faas-cli deploy -f todo-notify.yml --gateway http://127.0.0.1:8080
```

Test:

```powershell
curl -X POST http://127.0.0.1:8080/function/todo-notify `
  -H "Content-Type: application/json" `
  -d '{"title":"Portfolio demo"}'
```

Full guide: [serverless/openfaas/README.md](serverless/openfaas/README.md)

---

## Deployment — Edge node (K3s via k3d)

Simulates a resource-constrained edge site (lightweight service only):

```powershell
.\edge\setup-edge.ps1
curl http://localhost:8088
```

Guide: [edge/README.md](edge/README.md)

---

## Run without containers (development)

See [docs/SETUP_LOCAL_WITHOUT_DOCKER.md](docs/SETUP_LOCAL_WITHOUT_DOCKER.md).

---

## Architecture overview

```
Browser
   │
   ├─► Frontend (React)     :3000
   │
   └─► Backend (Express)    :5000  ──► PostgreSQL :5432
              │
              └──► OpenFaaS todo-notify (optional webhook)

Minikube: namespace acme-todo + Prometheus + Grafana
Edge:     k3d cluster acme-edge → edge-health (nginx)
```

---

## Infrastructure highlights

| Area | Implementation |
|------|----------------|
| Container images | Multi-stage Dockerfiles, non-root `node` user |
| Compose | Health checks, bridge network, named volume |
| Kubernetes | Deployments, Services, ConfigMap, Secret, PVC, probes |
| Security | NetworkPolicy tier isolation, RBAC ServiceAccounts |
| Monitoring | Prometheus scrape of `/metrics`, Grafana dashboards |
| Serverless | OpenFaaS `todo-notify` HTTP function |
| Edge | k3d + minimal nginx Deployment |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Docker daemon not running | Start Docker Desktop; retry `docker version` |
| Port 5000 in use (Windows) | Use `5001:5000` and `REACT_APP_API_URL=http://localhost:5001/api/todos` |
| Postgres 18 volume error | Compose uses `pgdata:/var/lib/postgresql` (see `docker-compose.yml`) |
| `ImagePullBackOff` on Minikube | Build images after `minikube docker-env \| Invoke-Expression` |
| NetworkPolicy not enforced | Restart Minikube with `--cni=calico` |
| Frontend loads, no todos | Check API URL matches published backend NodePort / host port |

---

## Portfolio documentation

| Document | Description |
|----------|-------------|
| [docs/TECHNICAL_LOGBOOK.md](docs/TECHNICAL_LOGBOOK.md) | Phase-by-phase engineering log |
| [docs/PROJECT_REPORT.md](docs/PROJECT_REPORT.md) | Comprehensive project report |
| [docs/PORTFOLIO_SUBMISSION.md](docs/PORTFOLIO_SUBMISSION.md) | Four-component submission checklist |
| [docs/SECURITY.md](docs/SECURITY.md) | Security design rationale |

---

## License

Assessment/educational use — ACMEInnovateNow fictional scenario (Cloud Technologies module).
