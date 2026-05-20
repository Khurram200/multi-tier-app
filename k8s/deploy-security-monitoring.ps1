# Security (NetworkPolicy, RBAC) + Prometheus/Grafana
# Prerequisite: .\k8s\deploy.ps1 and Minikube with Calico: minikube start --cni=calico
# Usage: .\k8s\deploy-security-monitoring.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

Write-Host "==> Rebuild backend image (/metrics)..." -ForegroundColor Cyan
$useMinikubeDocker = $true
minikube docker-env --shell powershell 2>$null | Invoke-Expression
if ($LASTEXITCODE -ne 0) {
    Write-Host "Using host Docker + minikube image load (multi-node or docker-env unavailable)" -ForegroundColor Yellow
    $useMinikubeDocker = $false
}
docker build -t todo-backend:latest ./backend
if ($LASTEXITCODE -ne 0) { exit 1 }
if (-not $useMinikubeDocker) {
    minikube image load todo-backend:latest
}

Write-Host "==> Rolling restart backend..." -ForegroundColor Cyan
kubectl rollout restart deployment/backend-deployment -n acme-todo
kubectl rollout status deployment/backend-deployment -n acme-todo --timeout=120s

Write-Host "==> Applying RBAC (ServiceAccounts, Roles, RoleBindings)..." -ForegroundColor Cyan
kubectl apply -f k8s/security/serviceaccounts.yaml
kubectl apply -f k8s/security/rbac.yaml

Write-Host "==> Applying NetworkPolicies..." -ForegroundColor Cyan
kubectl apply -f k8s/app-network-policies.yaml
kubectl apply -f k8s/security/network-policies.yaml

Write-Host "==> Re-applying app Deployments (service accounts)..." -ForegroundColor Cyan
kubectl apply -f k8s/db-deployment.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml

Write-Host "==> Applying monitoring stack..." -ForegroundColor Cyan
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/prometheus.yaml
kubectl apply -f k8s/monitoring/grafana.yaml
kubectl apply -f k8s/monitoring/grafana-dashboards.yaml

Write-Host "==> Waiting for Prometheus and Grafana..." -ForegroundColor Cyan
kubectl wait --for=condition=available deployment/prometheus -n acme-todo --timeout=120s
kubectl wait --for=condition=available deployment/grafana -n acme-todo --timeout=120s

Write-Host ""
Write-Host "==> Security & monitoring deployed" -ForegroundColor Green
kubectl get pods -n acme-todo
Write-Host ""
Write-Host "RBAC checks (frontend should be no, backend should be yes for db-secret):" -ForegroundColor Yellow
kubectl auth can-i get secret/db-secret --as=system:serviceaccount:acme-todo:frontend-sa -n acme-todo
kubectl auth can-i get secret/db-secret --as=system:serviceaccount:acme-todo:backend-sa -n acme-todo
Write-Host ""
Write-Host "Prometheus:" -ForegroundColor Yellow
minikube service prometheus -n acme-todo --url
Write-Host "Grafana (admin / admin):" -ForegroundColor Yellow
minikube service grafana -n acme-todo --url
Write-Host ""
Write-Host "NetworkPolicy test (frontend -> database should FAIL):" -ForegroundColor Yellow
Write-Host '  kubectl exec -n acme-todo deploy/frontend-deployment -- sh -c "nc -zv database 5432 2>&1 || echo BLOCKED"'
