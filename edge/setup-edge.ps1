# Create K3s edge cluster in Docker (k3d) and deploy lightweight edge-health service
# Usage: .\edge\setup-edge.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not (Get-Command k3d -ErrorAction SilentlyContinue)) {
    Write-Host "Install k3d first: https://k3d.io/ (choco install k3d)" -ForegroundColor Red
    exit 1
}

$cluster = "acme-edge"
$exists = k3d cluster list -o json | ConvertFrom-Json | Where-Object { $_.name -eq $cluster }

if (-not $exists) {
    Write-Host "==> Creating K3s edge cluster '$cluster' in Docker..." -ForegroundColor Cyan
    k3d cluster create $cluster `
        --servers 1 `
        --agents 0 `
        --api-port 6551 `
        --port "8088:80@loadbalancer"
} else {
    Write-Host "==> Cluster '$cluster' already exists" -ForegroundColor Yellow
}

kubectl config use-context "k3d-$cluster"
Write-Host "==> Deploying edge-health (nginx, low resources)..." -ForegroundColor Cyan
kubectl apply -f edge/k8s/edge-health.yaml
kubectl wait --for=condition=available deployment/edge-health -n edge --timeout=120s

Write-Host ""
Write-Host "==> Edge node ready" -ForegroundColor Green
kubectl get pods,svc -n edge
Write-Host ""
Write-Host "Edge service URL: http://localhost:8088" -ForegroundColor Yellow
Write-Host "Test: curl http://localhost:8088" -ForegroundColor Yellow
