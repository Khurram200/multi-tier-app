# Kubernetes deployment (Minikube)

These files deploy the same app as `docker-compose.yml`, but on a local Kubernetes cluster.

**Namespace:** `acme-todo`

## What you need

- Docker Desktop running  
- Minikube and kubectl installed  
- Enough RAM (I used 4GB for Minikube)

For the security lab work, start Minikube with Calico:

```powershell
minikube start --driver=docker --cpus=4 --memory=6144 --cni=calico
```

## Deploy the app

From the project root:

```powershell
.\k8s\deploy.ps1
```

The script:

1. Builds `todo-backend:latest` and `todo-frontend:latest` inside Minikube’s Docker
2. Applies postgres, backend, and frontend manifests
3. Sets the frontend API URL using `minikube ip`

Check everything is running:

```powershell
kubectl get pods -n acme-todo
```

Open the UI:

```powershell
minikube service frontend -n acme-todo --url
```

## Main files


| File                | Description                             |
| ------------------- | --------------------------------------- |
| `namespace.yaml`    | Creates `acme-todo` namespace           |
| `secret.yaml`       | Database passwords (local testing only) |
| `configmap.yaml`    | Environment variables and `init.sql`    |
| `postgres-pvc.yaml` | Storage for Postgres                    |
| `postgres.yaml`     | Database deployment and service         |
| `backend.yaml`      | API — NodePort 30050                    |
| `frontend.yaml`     | React app — NodePort 30030              |
| `deploy.ps1`        | Build + apply script                    |


## Security and monitoring

Run after the app works:

```powershell
.\k8s\deploy-security-monitoring.ps1
```

See `security/README.md` and `monitoring/README.md`.

## Remove everything

```powershell
kubectl delete namespace acme-todo
```

Or delete the whole cluster: `minikube delete`