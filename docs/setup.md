# Setup

Pipeline Information can be found [here](pipelines.md).

## Configure GitHub Secrets

Secrets are managed using [Github Repository Secrets](https://docs.github.com/en/actions/reference/encrypted-secrets) and are required to be created manually.

**Manually Created Secrets**

1. `AZURE_TENANT_ID`: The Azure AD Tenant being used.

2. `AZURE_SUBSCRIPTION_ID`: The Subscription ID that will be used for validation purposes.

3. `AZURE_CLIENT_ID`: An Azure AD Application with RBAC applied of _Owner_ Subscription Scope and any additional roles necessary for modules.

4. `AZURE_STAMP_ID`: An Azure AD Application that will be used when deploying a test stamp.

Authentication for Github Actions are using [Workload Identities](https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identities-overview) and an implementation of [OpenID Connect](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure) to ensure passwordless configuration and no Service Principal Secrets.