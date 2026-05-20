# Multi-tier To-Do App — Cloud Technologies Coursework

**Name:** Khurram Farooqui  
**Student ID:** 2325493  
**Module:** Cloud Technologies  
**GitHub:** https://github.com/Khurram200/multi-tier-app

This repository is my submission for the ACMEInnovateNow project. I took a simple three-tier to-do application (React, Node/Express, PostgreSQL) and deployed it using Docker, Kubernetes, basic security controls, monitoring, serverless (OpenFaaS), and a small edge setup with K3s.

The logbook and written report are submitted separately with my portfolio — this repo holds the **code and infrastructure files** plus instructions to run everything.

---

## What the application does

- View, add, edit, and delete tasks in a web UI  
- Data stored in PostgreSQL  
- REST API at `/api/todos`  
- Health check at `/health` and Prometheus metrics at `/metrics` on the backend  

---

## Project structure

| Folder / file | Purpose |
|---------------|---------|
| `backend/` | Express API + Dockerfile |
| `web/` | React frontend + Dockerfile |
| `db/init.sql` | Database table and sample data |
| `docker-compose.yml` | Run all three tiers with one command |
| `k8s/` | Kubernetes YAML files and PowerShell deploy scripts |
| `k8s/security/` | NetworkPolicy and RBAC |
| `k8s/monitoring/` | Prometheus and Grafana |
| `serverless/openfaas/` | `todo-notify` serverless function |
| `edge/` | k3d (K3s in Docker) with a small nginx service |

---

## Requirements

- Windows 10/11 (what I used) or similar  
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)  
- [Node.js](https://nodejs.org/) 18+ (only if running without Docker)  
- [Minikube](https://minikube.sigs.k8s.io/) and [kubectl](https://kubernetes.io/docs/tasks/tools/) for the Kubernetes tasks  
- [k3d](https://k3d.io/) for the edge task  
- Optional: [faas-cli](https://docs.openfaas.com/cli/install/) and arkade/Helm for OpenFaaS  

Check Docker is running:

```powershell
docker version
```

You should see both **Client** and **Server**. If not, start Docker Desktop first.

---

## 1. Docker Compose (containerisation)

This was the first way I ran the full app in containers.

```powershell
git clone https://github.com/Khurram200/multi-tier-app.git
cd multi-tier-app
docker compose up --build
```

Wait until you see the database healthy, backend started, and frontend compiled.

| What | URL |
|------|-----|
| Website | http://localhost:3000 |
| API | http://localhost:5000/api/todos |

Stop: `docker compose down`

**Note:** On my laptop port 5000 was already used. I changed the compose file to `5001:5000` and set `REACT_APP_API_URL=http://localhost:5001/api/todos` on the frontend service.

---

## 2. Run without Docker (optional)

Useful to understand each part before containerising.

1. Install PostgreSQL and create database `todo`  
2. Run: `psql -U postgres -d todo -f db/init.sql`  
3. Terminal 1: `cd backend` → copy `.env.example` to `.env` → `npm install` → `npm start`  
4. Terminal 2: `cd web` → `npm install` → `npm start`  

---

## 3. Kubernetes on Minikube

I converted the compose setup into Kubernetes manifests in the `k8s/` folder.

Start Minikube with Calico (needed for NetworkPolicy to work):

```powershell
minikube start --driver=docker --cpus=4 --memory=6144 --cni=calico
.\k8s\deploy.ps1
```

Check pods:

```powershell
kubectl get pods -n acme-todo
```

Get the frontend URL:

```powershell
minikube service frontend -n acme-todo --url
```

More steps: see [k8s/README.md](k8s/README.md)

---

## 4. Security and monitoring

After the app is running on Minikube:

```powershell
.\k8s\deploy-security-monitoring.ps1
```

This adds:

- **NetworkPolicy** — e.g. only the backend can reach the database on port 5432  
- **RBAC** — separate service accounts with limited permissions  
- **Prometheus + Grafana** — backend exposes `/metrics`  

Grafana (local only): login `admin` / `admin`  
See [k8s/security/README.md](k8s/security/README.md) and [k8s/monitoring/README.md](k8s/monitoring/README.md)

---

## 5. OpenFaaS (serverless)

I added a small function `todo-notify` that validates a todo title over HTTP. The main API still handles normal CRUD.

```powershell
.\serverless\openfaas\install-openfaas.ps1
kubectl port-forward -n openfaas svc/gateway 8080:8080
```

Then build and deploy — [serverless/openfaas/README.md](serverless/openfaas/README.md)

---

## 6. Edge computing (K3s with k3d)

The full app is too heavy for a realistic edge device, so on the edge cluster I only deployed a lightweight nginx status page.

```powershell
.\edge\setup-edge.ps1
```

Then open http://localhost:8088

Details: [edge/README.md](edge/README.md)

---

## Problems I ran into (and fixes)

| Issue | Fix |
|-------|-----|
| Docker not connecting | Start Docker Desktop |
| Postgres container failing | Use volume path `/var/lib/postgresql` for Postgres 18 |
| API/database login failed | Match `DB_PASSWORD` and `POSTGRES_PASSWORD` in compose |
| Port 5000 busy on Windows | Map `5001:5000` and update frontend API URL |
| `ImagePullBackOff` in K8s | Build images inside Minikube after `minikube docker-env` |
| Todos not loading on K8s | Set `REACT_APP_API_URL` to Minikube IP + backend NodePort |

---

## What I learned (short summary)

- How to write Dockerfiles with multi-stage builds and a non-root user  
- How Docker Compose links services with networks and volumes  
- How to map a compose file to Kubernetes Deployments, Services, Secrets, and ConfigMaps  
- Why network policies and RBAC matter in a multi-tier app  
- How to scrape basic metrics with Prometheus  
- When serverless is useful (small event functions) vs when to keep a normal API  
- How K3s/k3d can represent a smaller edge environment  

---

## Disclaimer

This is **university coursework**, not a production system. Passwords in `k8s/secret.yaml` are for local testing only and should not be reused in real deployments.
