# Portal Template (ARM)

??? info "_Article Audience_"
    :fontawesome-solid-user-tie:{ .lg .middle } __Domain Experts__: Working with OSDU services.

    :fontawesome-solid-chart-line:{ .lg .middle } __Data Scientists__: Working with data and machine learning.

    :fontawesome-solid-database:{ .lg .middle } __Data Engineers__: Working with data and databases.

The Azure Resource Manager (ARM) custom template deployment provides a simple way to provision the solution through the Azure Portal. This method uses a pre-configured ARM template that has been transpiled from Bicep, enabling rapid deployment through a guided portal experience.

??? Tip "Learning Opportunity"
    Learn more about [ARM Templates](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/overview) and how they work in Azure.

!!! Warning
    The template leverages complex configuration objects that are built in a way that can be integrated later with an [Azure Managed Application](https://learn.microsoft.com/en-us/azure/azure-resource-manager/managed-applications/overview).  This can make configuration of feature flags more challenging.


## Instructions

1. Create a [Microsoft Entra Application Registration](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app?tabs=certificate).

    === "Collected Values"
        - Application Client Id (clientId)
        - Application Client Secret (clientSecret)
        - Enterprise Application Object Id (principalId)


2. Open the custom ARM Template deployment.

    [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fosdu-developer%2Fmain%2Fazuredeploy.json)


3. Provide the required values.

    === "Required Values"
        - Email Address: _`Valid email address for the admin user`_
        - Application Client Id: _`Valid Client Id from the app registration`_
        - Application Client Secret: _`Valid Client Secret from the app registration`_
        - Application Client Principal OID: _`Valid Enterprise Application Object Id`_

4. Modify the optional parameters as desired.

    === "Optional Parameters"
        - Enable Burstable: _`Feature Flag: Enable burstable server types.`_
        - Custom VM Size: _`Set Custom VM size cluster nodes.`_
        - Ingress Type: _`Switch: Ingress type to use.`_
        - Enable Blob Public Access: _`Feature Flag: Enable Blob Storage public access.`_
        - Enable Manage: _`Feature Flag: Deploy virtual machine with bastion.`_
        - Vm Admin Username: _`Set admin username for the virtual machine.`_
        - Enable Pod Subnet: _`Feature Flag: Enhanced AKS subnet configuration.`_
        - Vnet Configuration: _`Network configuration object.`_
        - Cluster Software: _`Software configuration object.`_
        - Experimental Software: _`Experimental Software configuration object.`_
        - Cluster Network: _`Cluster network configuration object.`_
        - Cluster Network Plugin: _`Switch: Network plugin to use.`_
        - Cluster Admin Ids: _`Set cluster admin user ids to enable RBAC.`_

4. Deploy the Solution.

    !!! Warning
        Deployment can exceed 1 hour. Includes both infrastructure and software deployment.

4. Configure Authentication.

    === "Steps"
        - Locate the ingress IP address in the AKS service
        - Add a redirect URI to your Entra application:
            - Format: `https://<ingress_ip>/auth/spa/`
            - Platform type: Single-page application (SPA)

5. Validate Access.

    === "Portal"
        - Check Successful deployment in the resource group deployments
        - Check Successful deployment in the AKS gitops status

    === "API Access"
        - Navigate to `https://<ingress_ip>/auth/spa/`
        - Click Authorize to receive an authorization code
        - Use Get Tokens to retrieve an access token
        - Test the token with service swagger pages
