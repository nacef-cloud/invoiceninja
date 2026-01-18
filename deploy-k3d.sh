#!/bin/bash

set -e

echo "========================================="
echo "Invoice Ninja k3d Deployment Script"
echo "========================================="

# Configuration
IMAGE_NAME="invoice-registry:42489/invoiceninja"
IMAGE_TAG="local"
NAMESPACE="invoiceninja"
RELEASE_NAME="invoiceninja"
HELM_CHART_PATH="./helm/invoiceninja"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    log_error "kubectl is not installed"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    log_error "Helm is not installed"
    exit 1
fi

# Check k3d cluster
if ! kubectl cluster-info &> /dev/null; then
    log_error "No Kubernetes cluster found. Make sure k3d is running."
    exit 1
fi

log_info "✓ All prerequisites met"

# Build Docker image
log_info "Building Docker image..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

if [ $? -ne 0 ]; then
    log_error "Docker build failed"
    exit 1
fi

log_info "✓ Docker image built successfully"

# Push image to k3d registry
log_info "Pushing image to k3d registry..."
docker push ${IMAGE_NAME}:${IMAGE_TAG}

if [ $? -ne 0 ]; then
    log_error "Failed to push image to k3d registry"
    exit 1
fi

log_info "✓ Image pushed to k3d registry"

# Add Bitnami Helm repository
log_info "Adding Bitnami Helm repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

log_info "✓ Helm repository added"

# Update Helm dependencies
log_info "Updating Helm dependencies..."
cd ${HELM_CHART_PATH}
helm dependency update

if [ $? -ne 0 ]; then
    log_error "Failed to update Helm dependencies"
    exit 1
fi

cd - > /dev/null

log_info "✓ Helm dependencies updated"

# Create namespace
log_info "Creating namespace ${NAMESPACE}..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

log_info "✓ Namespace ready"

# Deploy Helm chart
log_info "Deploying Invoice Ninja..."
helm upgrade --install ${RELEASE_NAME} ${HELM_CHART_PATH} \
  --namespace ${NAMESPACE} \
  --set image.repository=${IMAGE_NAME} \
  --set image.tag=${IMAGE_TAG} \
  --set image.pullPolicy=IfNotPresent \
  --wait \
  --timeout 10m

if [ $? -ne 0 ]; then
    log_error "Helm deployment failed"
    exit 1
fi

log_info "✓ Deployment complete"

# Wait for pods to be ready
log_info "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/instance=${RELEASE_NAME} \
  -n ${NAMESPACE} \
  --timeout=5m

if [ $? -ne 0 ]; then
    log_warn "Some pods may not be ready yet. Check status with: kubectl get pods -n ${NAMESPACE}"
else
    log_info "✓ All pods are ready"
fi

# Generate APP_KEY if needed
log_info "Checking APP_KEY..."
CURRENT_KEY=$(kubectl get secret -n ${NAMESPACE} ${RELEASE_NAME}-secret -o jsonpath='{.data.APP_KEY}' | base64 -d)

if [ "$CURRENT_KEY" == "base64:CHANGEME_GENERATE_WITH_php_artisan_key_generate" ]; then
    log_warn "APP_KEY not set. Generating..."

    # Wait a bit for web pods to be fully ready
    sleep 10

    # Generate key
    NEW_KEY=$(kubectl exec -n ${NAMESPACE} deployment/${RELEASE_NAME}-web -- php artisan key:generate --show)

    if [ $? -eq 0 ]; then
        log_info "Generated APP_KEY: ${NEW_KEY}"

        # Update secret
        kubectl create secret generic ${RELEASE_NAME}-secret \
          --from-literal=APP_KEY="${NEW_KEY}" \
          --namespace ${NAMESPACE} \
          --dry-run=client -o yaml | kubectl apply -f -

        # Restart pods
        kubectl rollout restart deployment/${RELEASE_NAME}-web -n ${NAMESPACE}
        kubectl rollout restart deployment/${RELEASE_NAME}-queue -n ${NAMESPACE}

        log_info "✓ APP_KEY updated and pods restarted"
    else
        log_warn "Failed to generate APP_KEY. You may need to do this manually."
    fi
else
    log_info "✓ APP_KEY already set"
fi

echo ""
echo "========================================="
echo "Deployment Complete! 🎉"
echo "========================================="
echo ""
echo "Access Invoice Ninja:"
echo "  kubectl port-forward -n ${NAMESPACE} svc/${RELEASE_NAME}-web 8080:80"
echo "  Then visit: http://localhost:8080"
echo ""
echo "Check status:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo ""
echo "View logs:"
echo "  kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/component=web -f"
echo ""
echo "Credentials:"
echo "  MySQL:"
echo "    - User: ninja"
echo "    - Password: ninjapassword"
echo "    - Database: invoiceninja"
echo ""
echo "  MinIO (S3):"
echo "    - Access Key: minioadmin"
echo "    - Secret Key: minioadmin123"
echo ""
echo "========================================="
