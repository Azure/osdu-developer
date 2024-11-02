# Platform

The OSDU™ private instance solution implements industry-leading best practices for security and operational excellence on Azure Kubernetes Service (AKS). These practices are aligned with Microsoft's Secure Future Initiative and are designed to provide a robust, secure, and efficient platform while maintaining developer productivity.

??? Tip "Learning Opportunity"
    For more details on Microsoft's security focus, refer to the 
    [Microsoft Secure Future Initiative](https://www.microsoft.com/security/business/secure-future-initiative).

This solution implements comprehensive best practices across security controls and operational excellence. The implemented controls and features help ensure:

- Strong security posture through infrastructure and application security controls
- Operational efficiency through automation and DevOps practices
- Reliable performance through proper scaling and maintenance procedures
- Simplified maintenance through automated updates and proper backup strategies

??? Tip "Learning Opportunity"
    For more details on Microsoft's Cluster Best Practices, refer to the 
    [AKS Best Practices](https://learn.microsoft.com/en-us/azure/aks/best-practices).

## Security Controls

### Infrastructure Security

<div class="grid cards" markdown>

-   :material-shield-check:{ .lg .middle } __Cluster Protection__

    ---

    - [x] [Microsoft Defender for Containers](https://learn.microsoft.com/en-us/azure/defender-for-cloud/defender-for-containers-introduction) 
    
        Comprehensive security monitoring and protection for containerized assets including clusters, nodes, workloads, registries and images.

    - [x] [Kubernetes RBAC and Microsoft Entra ID](https://learn.microsoft.com/en-us/azure/aks/concepts-identity) 
    
        Granular access control by granting users, groups, and service accounts only the minimum required permissions through role-based policies and enhanced Azure authentication.

    - [x] [Node Resource Group Lockdown](https://learn.microsoft.com/en-us/azure/aks/node-resource-group-lockdown)
    
        Prevent unauthorized changes to node resource group resources using NRGLockdownPreview feature.

</div>   

<div class="grid cards" markdown>

-   :material-linux:{ .lg .middle } __Node Security__

    ---

    - [x] [Azure Linux](https://learn.microsoft.com/en-us/azure/aks/use-azure-linux)
    
        Azure Linux Container Host is optimized for container workloads on AKS, based on Microsoft's CBL-Mariner Linux distribution.

    - [x] [Disable SSH Access](https://learn.microsoft.com/en-us/azure/aks/disable-ssh-access)
    
        Improve security by disabling SSH access to nodes at both cluster and node pool levels using DisableSSHPreview feature.

</div>   

<div class="grid cards" markdown>

-   :material-network:{ .lg .middle } __Network Security__

    ---

    - [x] [CNI Overlay](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay)
    
        Enhanced network security with overlay networking, providing logical separation between pod and node networks.

    - [x] [NAT Gateway](https://learn.microsoft.com/en-us/azure/aks/nat-gateway)
    
        Managed outbound internet connectivity with network isolation capabilities.

    - [x] [Service Mesh](https://learn.microsoft.com/en-us/azure/aks/istio-deploy-addon)
    
        Istio service mesh for secure service-to-service communication, traffic management, and observability.

</div>

<div class="grid cards" markdown>

-   :material-database:{ .lg .middle } __Storage Security__

    ---

    - [x] [Managed Disks](https://learn.microsoft.com/en-us/azure/aks/azure-disk-customer-managed-keys)
    
        Secure block-level storage volumes with encryption and access controls.

</div>

### Application Security

<div class="grid cards" markdown>

-   :material-docker:{ .lg .middle } __Container Security__

    ---

    - [x] [Image Cleaner](https://learn.microsoft.com/en-us/azure/aks/image-cleaner)
    
        Automatic identification and removal of unused images to reduce vulnerability surface.

</div>

<div class="grid cards" markdown>

-   :material-shield-lock:{ .lg .middle } __Pod Security__

    ---

    - [x] [Pod Security Context](https://learn.microsoft.com/en-us/azure/aks/developer-best-practices-pod-security)
    
        Limit access to processes and services through security context settings, implementing principle of least privilege.

    - [x] [Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview)
    
        Enable pods to authenticate against Azure services using Microsoft Entra workload identities.

    - [x] [Secrets Management](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)
    
        Integrate Azure Key Vault with Secrets Store CSI Driver for secure runtime secrets management.

    - [x] [Policy Controls](https://learn.microsoft.com/en-us/azure/aks/policy-reference)
    
        Enforce Kubernetes best practices through Azure Policy deployment safeguards.

</div>

## Operational Excellence

### Automation & DevOps

<div class="grid cards" markdown>

-   :material-cog:{ .lg .middle } __Deployment & Operations__

    ---

    - [x] [GitOps](https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-flux2)
    
        Git-based infrastructure and application deployment management.

    - [x] [Verified Modules](https://learn.microsoft.com/en-us/azure/verified-modules/overview)
    
        Pre-validated infrastructure modules for consistent and secure deployments.

    - [x] [App Configuration](https://learn.microsoft.com/en-us/azure/azure-app-configuration/overview)
    
        Managed service for feature flags and configuration management.

</div>

### Scalability & Performance

<div class="grid cards" markdown>

-   :material-speedometer:{ .lg .middle } __Performance & Scaling__

    ---

    - [x] [Node Auto Provisioning](https://learn.microsoft.com/en-us/azure/aks/cluster-node-auto-provisioning)
    
        Automatic node provisioning for optimal cluster sizing and cost efficiency.

    - [x] [KEDA](https://learn.microsoft.com/en-us/azure/aks/keda-about)
    
        Event-driven autoscaling for Kubernetes workloads.

    - [x] [Vertical Pod Autoscaler](https://learn.microsoft.com/en-us/azure/aks/vertical-pod-autoscaler)
    
        Automated resource allocation optimization for pods based on usage patterns.

</div>

### Maintenance & Updates

<div class="grid cards" markdown>

-   :material-update:{ .lg .middle } __System Updates__

    ---

    - [x] [Automatic Upgrades](https://learn.microsoft.com/en-us/azure/aks/auto-upgrade-cluster?tabs=azure-cli)
    
        Stay current on new features and bug fixes with automated Kubernetes version upgrades.

    - [x] [Node OS Updates](https://learn.microsoft.com/en-us/azure/aks/node-updates-kured)
    
        Linux nodes in AKS get security patches through their distro update channel nightly.

</div>
