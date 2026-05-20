# Install OpenFaaS on Minikube (requires arkade or helm)
# Usage: .\serverless\openfaas\install-openfaas.ps1

$ErrorActionPreference = "Stop"

Write-Host "==> Checking Minikube..." -ForegroundColor Cyan
minikube status | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Start Minikube first: minikube start --cni=calico" -ForegroundColor Red
    exit 1
}

if (Get-Command arkade -ErrorAction SilentlyContinue) {
    Write-Host "==> Installing OpenFaaS via arkade..." -ForegroundColor Cyan
    arkade install openfaas
} elseif (Get-Command helm -ErrorAction SilentlyContinue) {
    Write-Host "==> Installing OpenFaaS via Helm..." -ForegroundColor Cyan
    kubectl create namespace openfaas --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace openfaas-fn --dry-run=client -o yaml | kubectl apply -f -
    helm repo add openfaas https://openfaas.github.io/faas-netes/ 2>$null
    helm repo update
    helm upgrade openfaas openfaas/openfaas --install --namespace openfaas --set functionNamespace=openfaas-fn --set generateBasicAuth=true
} else {
    Write-Host "Install arkade or helm first. See serverless/openfaas/README.md" -ForegroundColor Red
    exit 1
}

Write-Host "==> Waiting for OpenFaaS gateway..." -ForegroundColor Cyan
kubectl rollout status deployment/gateway -n openfaas --timeout=300s

Write-Host ""
Write-Host "==> OpenFaaS installed" -ForegroundColor Green
kubectl get pods -n openfaas
Write-Host ""
Write-Host "Port-forward gateway:" -ForegroundColor Yellow
Write-Host "  kubectl port-forward -n openfaas svc/gateway 8080:8080"
Write-Host ""
Write-Host "Deploy function:" -ForegroundColor Yellow
Write-Host "  cd serverless/openfaas"
Write-Host "  minikube docker-env --shell powershell | Invoke-Expression"
Write-Host "  faas-cli build -f todo-notify.yml"
Write-Host "  faas-cli deploy -f todo-notify.yml --gateway http://127.0.0.1:8080"
