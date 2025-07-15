#!/bin/bash

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m'

print_step() {
  echo -e "\n${GREEN}==> $1${NC}"
}

print_step "[1/5] Checking if K3s is installed"
if ! command -v k3s &> /dev/null && ! command -v kubectl &> /dev/null; then
  echo "K3s not found. Installing K3s..."

  PUBLIC_IP=$(curl -s ifconfig.me)
  TOKEN="UbvEc4BpB5YaqEVdqrS81yt/+wSReOaM" # replace if needed

  curl -sfL https://get.k3s.io | sh -s - server \
    --disable traefik \
    --write-kubeconfig-mode=644 \
    --node-name="$(hostname -f)" \
    --kubelet-arg="cloud-provider=external" \
    --tls-san="${PUBLIC_IP}" \
    --token="${TOKEN}"

else
  echo "K3s already installed. Skipping."
fi

print_step "[2/5] Applying Metrics Server (for K3s + VM support)"
kubectl apply -f manifests/metrics_server.yaml

print_step "[3/5] Applying Argo Workflow CRDs with admin-level permissions"

kubectl apply -f manifests/workflow-crds.yaml

# Create cluster role for workflow-controller with admin access
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argo-workflow-admin
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
- nonResourceURLs: ["*"]
  verbs: ["*"]
EOF

# Bind to default service account in argo namespace
kubectl create namespace argo || true
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argo-workflow-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: argo-workflow-admin
subjects:
- kind: ServiceAccount
  name: default
  namespace: argo
EOF

print_step "[4/5] Applying Internal Docker Registry (NodePort: 30100)"
kubectl create namespace kube-registry || true
kubectl apply -f manifests/internal-registry.yaml

print_step "[5/5] Installing Traefik Ingress with Let's Encrypt"
kubectl apply -f manifests/trafek.yaml

print_step "✅ All prerequisites installed successfully!"
echo -e "\nTo verify, run: \nkubectl get pods -A"

print_step "🔑 Exporting Kubeconfig"

K3S_CONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
OUTPUT_KUBECONFIG="./kubeconfig"

if [ -f "$K3S_CONFIG_PATH" ]; then
  sudo cp "$K3S_CONFIG_PATH" "$OUTPUT_KUBECONFIG"
  sudo chown $USER:$USER "$OUTPUT_KUBECONFIG"
  echo -e "${GREEN}Saved kubeconfig to: ${OUTPUT_KUBECONFIG}${NC}"
  echo "You can now run: export KUBECONFIG=$(pwd)/kubeconfig"
else
  echo "⚠️  K3s kubeconfig not found at $K3S_CONFIG_PATH"
fi