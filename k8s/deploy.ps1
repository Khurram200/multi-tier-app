# Deploy to Minikube — manifest layout matches multi-tier-app - Copy/k8s
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

Write-Host "==> Building images..." -ForegroundColor Cyan
$useMinikubeDocker = $true
minikube docker-env --shell powershell 2>$null | Invoke-Expression
if ($LASTEXITCODE -ne 0) {
    Write-Host "Using host Docker + minikube image load (multi-node or docker-env unavailable)" -ForegroundColor Yellow
    $useMinikubeDocker = $false
}
docker build -t todo-backend:latest ./backend
if ($LASTEXITCODE -ne 0) { exit 1 }
docker build -t todo-frontend:latest ./web
if ($LASTEXITCODE -ne 0) { exit 1 }
if (-not $useMinikubeDocker) {
    minikube image load todo-backend:latest
    minikube image load todo-frontend:latest
}

Write-Host "==> Applying manifests..." -ForegroundColor Cyan
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/security/serviceaccounts.yaml
kubectl apply -f k8s/db-secret.yaml
kubectl apply -f k8s/db-init-script-configmap.yaml
kubectl apply -f k8s/frontend-configmap.yaml
kubectl apply -f k8s/db-pvc.yaml
kubectl apply -f k8s/db-deployment.yaml
kubectl apply -f k8s/db-service.yaml

Write-Host "==> Waiting for database..." -ForegroundColor Cyan
kubectl wait --for=condition=ready pod -l app=database -n acme-todo --timeout=180s
if ($LASTEXITCODE -ne 0) { exit 1 }

kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
Write-Host "==> Waiting for backend..." -ForegroundColor Cyan
kubectl wait --for=condition=ready pod -l app=backend -n acme-todo --timeout=180s
if ($LASTEXITCODE -ne 0) { exit 1 }

$ip = minikube ip
$apiUrl = "http://${ip}:30050/api/todos"
Write-Host "==> Setting REACT_APP_API_URL to $apiUrl" -ForegroundColor Cyan
kubectl patch configmap frontend-configmap -n acme-todo --type merge -p "{`"data`":{`"REACT_APP_API_URL`":`"$apiUrl`"}}"

kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
Write-Host "==> Waiting for frontend (CRA compile may take 1-2 min)..." -ForegroundColor Cyan
kubectl wait --for=condition=ready pod -l app=frontend -n acme-todo --timeout=300s

Write-Host ""
Write-Host "==> Deployment complete" -ForegroundColor Green
kubectl get pods,svc -n acme-todo
Write-Host ""
Write-Host "Frontend URL:" -ForegroundColor Yellow
minikube service frontend-service -n acme-todo --url
Write-Host "Backend API:" -ForegroundColor Yellow
minikube service backend-service -n acme-todo --url
