# Invoice Ninja Helm Chart

This Helm chart deploys Invoice Ninja on Kubernetes with all required dependencies.

## Features

- ✅ Stateless web application (horizontally scalable)
- ✅ Queue workers for background jobs
- ✅ Laravel scheduler (CronJob)
- ✅ MySQL database (Bitnami chart)
- ✅ Redis for caching and queues (Bitnami chart)
- ✅ MinIO for S3-compatible storage (Bitnami chart)
- ✅ Gotenberg for PDF generation
- ✅ Health checks and probes
- ✅ Ingress support

## Prerequisites

- Kubernetes 1.20+
- Helm 3.8+
- kubectl configured to access your cluster

## Quick Start

### 1. Add Bitnami Repository

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 2. Update Dependencies

```bash
cd helm/invoiceninja
helm dependency update
```

### 3. Install the Chart

```bash
helm install invoiceninja . \
  --create-namespace \
  --namespace invoiceninja
```

### 4. Generate APP_KEY

```bash
# Generate application key
kubectl exec -n invoiceninja deployment/invoiceninja-web -- php artisan key:generate --show

# Update secret
kubectl create secret generic invoiceninja-secret \
  --from-literal=APP_KEY='base64:YOUR_GENERATED_KEY_HERE' \
  --namespace invoiceninja \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods
kubectl rollout restart deployment/invoiceninja-web -n invoiceninja
```

### 5. Access the Application

```bash
# Port forward to access locally
kubectl port-forward -n invoiceninja svc/invoiceninja-web 8080:80

# Visit http://localhost:8080
```

## Configuration

See `values.yaml` for all configuration options.

### Common Configurations

#### Custom Domain

```yaml
app:
  url: "https://invoices.yourdomain.com"

ingress:
  enabled: true
  hosts:
    - host: invoices.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: invoiceninja-tls
      hosts:
        - invoices.yourdomain.com
```

#### External Database

```yaml
mysql:
  enabled: false

database:
  host: your-external-db-host
  port: 3306
  name: invoiceninja
  username: ninja
  password: your-password
```

#### External Redis

```yaml
redis:
  enabled: false

redis:
  host: your-external-redis-host
  port: 6379
  password: your-password
```

#### Scaling

```yaml
replicaCount:
  web: 5
  queue: 3

autoscaling:
  enabled: true
  web:
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

## Uninstalling

```bash
helm uninstall invoiceninja -n invoiceninja
kubectl delete namespace invoiceninja
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n invoiceninja
kubectl describe pod -n invoiceninja <pod-name>
```

### View Logs

```bash
# Web logs
kubectl logs -n invoiceninja -l app.kubernetes.io/component=web -f

# Queue logs
kubectl logs -n invoiceninja -l app.kubernetes.io/component=queue -f

# Scheduler logs
kubectl logs -n invoiceninja -l app.kubernetes.io/component=scheduler
```

### Common Issues

1. **APP_KEY not set**: Follow step 4 in Quick Start
2. **Database connection failed**: Check MySQL pod status and credentials
3. **Pods not starting**: Check resource limits and available cluster resources

## Support

- Documentation: https://invoiceninja.github.io/
- Forum: https://forum.invoiceninja.com/
- GitHub: https://github.com/invoiceninja/invoiceninja
