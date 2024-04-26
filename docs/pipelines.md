# Continuous Workflows

A number of CI workflows are leveraged in this repo to test the bicep files to ensure quality is high. The attempt is to use good patterns and practices for working with Infrastructure as Code.

### Pre-deploy Validation

It's essential to catch as many problems before a single resource is deployed to real infrastructure. There are a lot of tools and techniques that can be leveraged to catch functional or syntactical problems depending on your authoring language and platform.

#### PSRule for Azure

An interesting project for performing pre/post validation of Azure Resources against the [Well Architected Framework](https://learn.microsoft.com/en-us/azure/architecture/framework/) is [PSRule for Azure](https://azure.github.io/PSRule.Rules.Azure/). Over [200 rules](https://azure.github.io/PSRule.Rules.Azure/en/baselines/Azure.All/) will be evaluated against your Arm template, ranging from Security configuration to naming conventions.

#### Using the AZ CLI to verify

As a minimum bar to assert the quality of the bicep code we really want to leverage some additional validation of "would this deploy successfully" and "what will this create", but without actually creating any actual Infrastructure resources.

To do this we need to talk to the Azure Control Plane, so we'll need an Azure Application with Federated OIDC, an Azure Subscription with RBAC for the Azure Application configured and a resource group.

1. [Validation](https://docs.microsoft.com/en-us/cli/azure/deployment/group?view=azure-cli-latest#az_deployment_group_validate). Validation ensures the template compiles, that there are no errors in the bicep code, that the parameter file provides all mandatory parameters and that the ARM Control plane will accept the deployment. A great example of what Validate can do is that it will fail if you supply incompatible configuration through parameters, eg. You want a feature of an Azure service that comes with a Premium SKU but you've set the SKU to Standard.

1. [What-If](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-what-if). The what-if operation lets you see how resources will change if you deploy the template.

After running a What-If, we have the opportunity to leverage the output of the WhatIf to assert a level of quality of what's been written. This is especially useful when your bicep template contains a lot of conditional logic. EG. If you're using parameter values to choose whether or not to install certain resources it can be especially useful to write a couple of test cases around this.

There might also be a number of rules specific to your enterprise you wish may want to enforce to guide best practices that cannot be done using [Azure Policy](https://docs.microsoft.com/en-us/azure/governance/policy/overview), such as resource naming conventions.

### Deploying to an Azure Subscription

By running the Validation and WhatIf, you'll already have achieved a good level of rigour on quality, however there are gaps (Key Vault soft delete, Diagnostic Setting category validation, to name but two) with these validation tests - and the only way to know for sure if your template works is to deploy it.

Actually deploying your IaC template as part of the development process also supports;

- Enabling integration tests for more complex infrastructure deployments.
- Documented evidence of the IaC working with associated logs, great for future analysis if things break.
- Seeing the end to end time it takes to deploy, so you can provide guidance to the teams who consume your code template.

Consider how often you'll employ this technique, as there are `cost implications`. It also adds a significant delay into your pipeline.

In this repo we run a real deployment and integration tests each week on a schedule, not for every push of the code.

### Post-deploy Validation

The fact that a deployment completes successfully is a great sign in itself, however there are several post deployment checks that can be run to verify the usability of the IaC code that's been new'd up.

The first, and often easiest activity is to test using the service. Attempting to contact the service endpoint is firmly in the realm of integration testing, not just because of the many deployed services working together but also because of the configuration of those services and restrictions in place in the environment you're deploying to.

## Solution actions used in this repo

### Infra - Test

This action will run a Validate Step to ensure any changes to bicep is acceptable. It also will trigger a Standards Check that is non blocking in order to determine if the solution passes the PSRule checks.

### Infra - Build

This action ensures that the bicep can build properly.

### Infra - Release

The release action will run whenever a release is created to ensure we have a copy of the ARM template from that release that could then be used by other systems as necessary.

```mermaid
sequenceDiagram
    participant Workflow as "GitHub Workflow"

    participant Azure as "Azure/login@v2"
    participant anothrNick as "github-tag-action@1.69.0"
    participant bashCommand as "bash"
    participant pwshCommand as "pwsh"
    participant mikepenz as "elease-changelog-builder-action@v1"
    participant EndBug as "add-and-commit@v9"
    participant ncipollo as "release-action@v1"


    Workflow->>Workflow: Manual Trigger
    Workflow->>Workflow: Code Checkout
    Workflow->>Azure: Azure Login
    Workflow->>anothrNick: New Tag
    Workflow->>bashCommand: Version Update
    Workflow->>pwshCommand: Bicep Install
    Workflow->>pwshCommand: Bicep Build
    Workflow->>mikepenz: Generate Changes
    Workflow->>EndBug: Git Commit
    Workflow->>ncipollo: Create Release
```

## Misc actions used in this repo

### Auto -Documentation Check

This is a super simple action that runs a _spell check_ on any `.md` files in the repo. It's useful to catch simple mistakes from quick edits or other peoples PR's. This action is also part of the branch policy for merging to main.

### Auto - Greet

This is an auto action for a bot to reply to open issues and open pull requests.

### Auto - Label

This is an auto action for a bot to automatically apply labels based on detection of type of code change.
