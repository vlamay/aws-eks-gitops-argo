#!/bin/bash
# Install Argo CD Script
# Installs Argo CD with custom configuration

set -e

ARGOCD_VERSION="${ARGOCD_VERSION:-stable}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Create namespace
print_info "Creating Argo CD namespace..."
kubectl create namespace "$ARGOCD_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
print_success "Namespace created"

# Install Argo CD
print_info "Installing Argo CD ($ARGOCD_VERSION)..."
kubectl apply -n "$ARGOCD_NAMESPACE" -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
print_success "Argo CD manifests applied"

# Wait for CRDs
print_info "Waiting for CRDs to be established..."
kubectl wait --for=condition=established --timeout=60s crd/applications.argoproj.io 2>/dev/null || true
kubectl wait --for=condition=established --timeout=60s crd/applicationsets.argoproj.io 2>/dev/null || true
kubectl wait --for=condition=established --timeout=60s crd/appprojects.argoproj.io 2>/dev/null || true
print_success "CRDs established"

# Wait for deployments
print_info "Waiting for Argo CD components to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n "$ARGOCD_NAMESPACE"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n "$ARGOCD_NAMESPACE"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-redis -n "$ARGOCD_NAMESPACE"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-dex-server -n "$ARGOCD_NAMESPACE"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-applicationset-controller -n "$ARGOCD_NAMESPACE"
print_success "Argo CD components ready"

# Apply custom configuration if exists
if [ -f "kubernetes/argocd/argocd-config.yaml" ]; then
    print_info "Applying custom Argo CD configuration..."
    kubectl apply -f kubernetes/argocd/argocd-config.yaml
    print_success "Custom configuration applied"
fi

# Get initial admin password
print_info "Argo CD installation complete!"
echo ""
echo "Argo CD Credentials:"
echo "  Username: admin"
echo -n "  Password: "
kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""
print_info "To access Argo CD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Open: https://localhost:8080"
echo ""
print_warning "Change the admin password after first login!"
