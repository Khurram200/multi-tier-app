# OpenFaaS — todo-notify function

Serverless part of the project. The function checks if a todo `title` is valid (not empty, max 255 characters) and returns a JSON response.

The normal API in `backend/` still does create/read/update/delete. This function is extra — an example of event-style processing.

## Install OpenFaaS

Minikube must already be running.

```powershell
.\serverless\openfaas\install-openfaas.ps1
```

You need arkade or Helm installed. Then port-forward:

```powershell
kubectl port-forward -n openfaas svc/gateway 8080:8080
```

## Deploy the function

```powershell
cd serverless\openfaas
minikube docker-env --shell powershell | Invoke-Expression
faas-cli build -f todo-notify.yml
faas-cli deploy -f todo-notify.yml --gateway http://127.0.0.1:8080
```

## Test

```powershell
curl -X POST http://127.0.0.1:8080/function/todo-notify -H "Content-Type: application/json" -d "{\"title\":\"Study for exam\"}"
```

If `title` is empty you should get an error response.

## Optional link to the API

If you set `OPENFAAS_TODO_NOTIFY_URL` on the backend, creating a todo will also call this function in the background (see `backend/server.js`).