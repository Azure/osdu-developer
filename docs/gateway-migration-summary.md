# Gateway API Migration Summary

## Overview
Successfully migrated from Istio VirtualServices to Gateway API HTTPRoutes while maintaining both internal and external gateway access.

## Architecture

### Istio Gateway Services (Physical Layer)
Deployed via `software/components/osdu-system/mesh.yaml`:

1. **External Gateway Service**: `external-gateway-istio`
   - Service Type: LoadBalancer (external IP)
   - Annotation: `service.beta.kubernetes.io/azure-load-balancer-internal: 'false'`
   - Accessible from internet

2. **Internal Gateway Service**: `internal-gateway-istio`  
   - Service Type: LoadBalancer (internal IP: 10.224.0.13)
   - Annotation: `service.beta.kubernetes.io/azure-load-balancer-internal: 'true'`
   - Accessible only within VNet

### Gateway API Gateways (Logical Layer)
Deployed via `charts/istio-ingress/templates/gateways.yaml`:

1. **external-gateway**: Bound to `external-gateway-istio` service
2. **internal-gateway**: Bound to `internal-gateway-istio` service

## Routing Configuration

### HTTPRoutes with Dual Gateway Access
All services are configured to accept traffic from both gateways:

1. **Web Site** (`software/applications/web-site/httproute.yaml`)
   - Path: `/` (root)
   - Accessible via both external and internal IPs

2. **Airflow** (`software/components/airflow/httproute.yaml`)
   - Path: `/airflow`
   - Accessible via both external and internal IPs

3. **Admin UI** (`software/experimental/admin-ui/httproute.yaml`)
   - Path: `/adminui` (rewrites to `/`)
   - Accessible via both external and internal IPs

4. **OSDU Services** (Chart templates)
   - osdu-developer-service: Multiple API services with configured paths
   - osdu-developer-auth: Authentication services at `/auth` and `/auth/spa/`

## Verification Commands

### Check Gateway Services
```powershell
# Check external gateway service (should have external IP)
kubectl get svc external-gateway-istio -n istio-system

# Check internal gateway service (should have internal IP: 10.224.0.13)
kubectl get svc internal-gateway-istio -n istio-system
```

### Check Gateway API Resources
```powershell
# Check Gateway API gateways
kubectl get gateways -n istio-system

# Check HTTPRoutes across all namespaces
kubectl get httproutes -A

# Check ReferenceGrants for cross-namespace permissions
kubectl get referencegrants -A
```

### Test External Access
```powershell
# Get external IP
$EXTERNAL_IP = kubectl get svc external-gateway-istio -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Test web site
curl "http://$EXTERNAL_IP/"

# Test airflow  
curl "http://$EXTERNAL_IP/airflow"

# Test admin UI
curl "http://$EXTERNAL_IP/adminui"
```

### Test Internal Access
```powershell
# From within VNet (e.g., from a pod or VM in the VNet)
curl "http://10.224.0.13/"
curl "http://10.224.0.13/airflow"
curl "http://10.224.0.13/adminui"
```

## Migration Changes Made

### 1. Updated Istio Gateway Services (`mesh.yaml`)
- Added unique names and labels for each gateway service
- `external-gateway-istio` and `internal-gateway-istio`
- Proper LoadBalancer annotations for internal vs external access

### 2. Updated Gateway API Configuration (`gateways.yaml`)
- Added `addresses` field to bind gateways to specific services
- Added proper labels for identification

### 3. Created HTTPRoute Files
- **Charts**: Template-based HTTPRoutes with ReferenceGrants
- **Applications**: Static HTTPRoute files with dual gateway access
- **Components**: HTTPRoute files replacing VirtualServices

### 4. Commented Out VirtualServices
- All original VirtualService files marked as deprecated
- Pointed to new HTTPRoute equivalents

## Key Benefits

1. **Standard Compliance**: Using Gateway API instead of Istio-specific VirtualServices
2. **Dual Access**: Services available via both internal (VNet) and external (internet) IPs
3. **Cross-namespace Security**: ReferenceGrants provide secure cross-namespace routing
4. **CORS Support**: Migrated to response header modifiers
5. **Future Proof**: Gateway API is the standard for Kubernetes ingress

## Troubleshooting

### If Internal Gateway Not Working
1. Verify internal gateway service has internal IP: `kubectl get svc internal-gateway-istio -n istio-system`
2. Check VNet connectivity from client
3. Verify HTTPRoute references correct gateway: `kubectl describe httproute <name> -n <namespace>`

### If External Gateway Not Working  
1. Verify external gateway service has public IP
2. Check DNS configuration (if using FQDN)
3. Verify certificate configuration for HTTPS

### If HTTPRoutes Not Working
1. Check gateway status: `kubectl describe gateway external-gateway -n istio-system`
2. Check ReferenceGrant permissions: `kubectl get referencegrants -A`
3. Verify Istio proxy configuration: `istioctl proxy-config routes <pod>`
