# Apply security (NetworkPolicy, RBAC) and monitoring (Prometheus, Grafana)
# Prerequisite: app deployed via k8s/deploy.ps1 and Minikube with Calico CNI
# Usage: .\k8s\deploy-security-monitoring.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

Write-Host "==> Rebuild backend image (prom-client /metrics)..." -ForegroundColor Cyan
minikube docker-env --shell powershell | Invoke-Expression
docker build -t todo-backend:latest ./backend
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "==> Rolling restart backend..." -ForegroundColor Cyan
kubectl rollout restart deployment/backend -n acme-todo
kubectl rollout status deployment/backend -n acme-todo --timeout=120s

Write-Host "==> Applying security (ServiceAccounts, RBAC, NetworkPolicies)..." -ForegroundColor Cyan
kubectl apply -f k8s/security/serviceaccounts.yaml
kubectl apply -f k8s/security/rbac.yaml
kubectl apply -f k8s/security/network-policies.yaml

Write-Host "==> Re-applying app deployments (service accounts)..." -ForegroundColor Cyan
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/frontend.yaml

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
kubectl get pods -n acme-todo -l 'app in (prometheus,grafana,backend,frontend,postgres)'
Write-Host ""
Write-Host "Prometheus UI:" -ForegroundColor Yellow
minikube service prometheus -n acme-todo --url
Write-Host "Grafana UI (admin / admin):" -ForegroundColor Yellow
minikube service grafana -n acme-todo --url
Write-Host ""
Write-Host "Test NetworkPolicy (frontend -> postgres should FAIL):" -ForegroundColor Yellow
Write-Host '  kubectl exec -n acme-todo deploy/frontend -- sh -c "nc -zv postgres 5432 2>&1 || true"'
