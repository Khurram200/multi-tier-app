# Deploy multi-tier-app to Minikube (Windows PowerShell)
# Usage: .\k8s\deploy.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

Write-Host "==> Checking Minikube..." -ForegroundColor Cyan
minikube status | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Starting Minikube..."
    minikube start --driver=docker --cpus=4 --memory=4096
}

Write-Host "==> Building images in Minikube Docker..." -ForegroundColor Cyan
minikube docker-env --shell powershell | Invoke-Expression
docker build -t todo-backend:latest ./backend
if ($LASTEXITCODE -ne 0) { exit 1 }
docker build -t todo-frontend:latest ./web
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "==> Applying manifests..." -ForegroundColor Cyan
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/security/serviceaccounts.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres.yaml

Write-Host "==> Waiting for Postgres..." -ForegroundColor Cyan
kubectl wait --for=condition=ready pod -l app=postgres -n acme-todo --timeout=180s
if ($LASTEXITCODE -ne 0) { exit 1 }

kubectl apply -f k8s/backend.yaml
Write-Host "==> Waiting for Backend..." -ForegroundColor Cyan
kubectl wait --for=condition=ready pod -l app=backend -n acme-todo --timeout=180s
if ($LASTEXITCODE -ne 0) { exit 1 }

$ip = minikube ip
$apiUrl = "http://${ip}:30050/api/todos"
Write-Host "==> Setting REACT_APP_API_URL to $apiUrl" -ForegroundColor Cyan
kubectl patch configmap app-config -n acme-todo --type merge -p "{`"data`":{`"REACT_APP_API_URL`":`"$apiUrl`"}}"

kubectl apply -f k8s/frontend.yaml
Write-Host "==> Waiting for Frontend (CRA compile may take 1-2 min)..." -ForegroundColor Cyan
kubectl wait --for=condition=ready pod -l app=frontend -n acme-todo --timeout=300s

Write-Host ""
Write-Host "==> Deployment complete" -ForegroundColor Green
kubectl get pods,svc -n acme-todo
Write-Host ""
Write-Host "Frontend URL:" -ForegroundColor Yellow
minikube service frontend -n acme-todo --url
Write-Host "Backend API (append /api/todos):" -ForegroundColor Yellow
minikube service backend -n acme-todo --url
