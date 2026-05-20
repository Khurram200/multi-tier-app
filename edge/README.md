# Edge node — K3s in Docker (k3d)

For the edge computing part of the assignment I used **k3d** to run a small **K3s** cluster inside Docker. This simulates a low-resource edge site.

I did **not** deploy the full todo app here (Postgres + React would be too heavy). Instead there is a small **nginx** page with low CPU/memory limits.

The main application stays on Minikube.

## Setup

Install k3d, then from the project root:

```powershell
.\edge\setup-edge.ps1
```

Open [http://localhost:8088](http://localhost:8088) in a browser.

## What gets created

- k3d cluster name: `acme-edge`  
- Namespace: `edge`  
- Deployment: `edge-health` (nginx:alpine, small resource limits)

## Clean up

```powershell
k3d cluster delete acme-edge
```

