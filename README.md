# Opslync Platform - Prerequisites Setup

This setup script installs the core dependencies needed for running the Opslync Internal Developer Platform on a local K3s-based Kubernetes cluster.

## 📋 Requirements

- OS: Linux/macOS (with sudo access)
- K3s-compatible VM or host
- curl & kubectl installed (or auto-installed via script)
- Internet connectivity

---

## 🚀 Installation Steps

### 1. Clone This Repository
```bash
git clone https://github.com/YOUR_ORG/opslync-prerequisites.git
cd opslync-prerequisites
```

### 2. Run the Installer Script
```bash
chmod +x install.sh
./install.sh
```

The script will:
- Install K3s if not already installed
- Apply:
  - ✅ Metrics Server (K3s-compatible)
  - ✅ Argo Workflow CRDs + Admin RBAC
  - ✅ Internal Docker Registry (NodePort 30100)
  - ✅ Traefik Ingress Controller (with Let's Encrypt)

---

## 📁 Manifests Overview

| Manifest                | Description                              |
|------------------------|------------------------------------------|
| `metrics_server.yaml`  | Metrics API for Pods & Nodes             |
| `workflow-crds.yaml`   | Argo Workflow CRDs for pipelines         |
| `internal-registry.yaml` | Local Docker registry (port 30100)     |
| `trafek.yaml`          | Traefik ingress with Let's Encrypt       |

---

## ✅ Validation
After installation, verify all pods:
```bash
kubectl get pods -A
```
Expected namespaces:
- `kube-system`
- `kube-registry`
- `argo`
- `traefik`

Expected services:
```bash
kubectl get svc -A
```

---

## 🛠 Troubleshooting

### Q: "Certificate not issued" on Traefik?
- Make sure port 80/443 are open (use `sudo netstat -tuln | grep :80\|:443`)
- DNS record must point to the VM IP

### Q: "Metrics not visible in K9s/Grafana"
- Ensure metrics-server pod is running
- Try restarting with `kubectl rollout restart deployment metrics-server -n kube-system`

---

## 💡 Next Steps
After the setup:
- Access Traefik Dashboard (port 8080)
- Push Docker images to `localhost:30100`
- Deploy workflows via Argo (UI or CLI)

---

## 📦 Advanced (coming soon)
- `.env` support for custom config
- Skip components via flags (e.g., `--no-registry`)
- Remote YAMLs from GitHub/CDN
