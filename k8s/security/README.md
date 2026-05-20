# Security — NetworkPolicy and RBAC

Part of my Cloud Technologies security task. Files are in this folder and applied with `deploy-security-monitoring.ps1`.

## Important: use Calico

NetworkPolicy did not work for me until I restarted Minikube with:

```powershell
minikube start --cni=calico
```

Then redeploy the application.

## NetworkPolicy (what I was trying to show)

- The **database** only accepts connections from the **backend** pod on port 5432  
- The **frontend pod** cannot connect directly to Postgres (only DNS egress)  
- The browser still uses the API through NodePort on the host — that is normal  

Test from the frontend pod (should fail or show BLOCKED):

```powershell
kubectl exec -n acme-todo deploy/frontend -- sh -c "nc -zv postgres 5432 2>&1 || echo BLOCKED"
```

## RBAC

Each service has its own ServiceAccount:

| Account | Can do |
|---------|--------|
| frontend-sa | Read ConfigMap `app-config` only |
| backend-sa | Read ConfigMap + Secret `app-secrets` |
| postgres-sa | Read its PVC |
| prometheus-sa | List pods/services for scraping |

Check permissions:

```powershell
kubectl auth can-i get secrets/app-secrets --as=system:serviceaccount:acme-todo:frontend-sa -n acme-todo
kubectl auth can-i get secrets/app-secrets --as=system:serviceaccount:acme-todo:backend-sa -n acme-todo
```

Frontend should be **no**, backend should be **yes**.

## Apply manually

```powershell
kubectl apply -f k8s/security/
```
