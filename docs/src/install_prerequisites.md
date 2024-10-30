# Prerequisites

??? info "_Article Audience_"
    :fontawesome-solid-code:{ .lg .middle } __Application Developer__: Working with Services and Applications

    :fontawesome-solid-cloud:{ .lg .middle } __Cloud Architects__: Working with Infrastructure and Software

    :fontawesome-brands-git-alt:{ .lg .middle } __DevOps Engineers__: Automation and Deployment Customizations

This guide outlines the software tools you need installed locally to work with the solution. 

#### Operating System Support

<div class="grid cards" markdown>

-   :fontawesome-brands-apple:{ .lg .middle } __macOS__

-   :fontawesome-brands-linux:{ .lg .middle } __Linux__

-   :fontawesome-brands-windows:{ .lg .middle } __Windows__

</div>




### Visual Studio Code
Visual Studio Code is a lightweight but powerful source code editor. Install it along with the REST Client Extension for testing and interacting with REST APIs.

:material-download:{ .lg .middle } [Download Visual Studio Code](https://code.visualstudio.com/download)

### PowerShell Core
PowerShell Core is a cross-platform task automation solution, useful for scripting and automation tasks in our solution.

:material-download:{ .lg .middle } [Download PowerShell Core](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.4)

### Azure CLI
The Azure Command-Line Interface (CLI) is a set of commands used to create and manage Azure resources. It's essential for managing your Azure environment.

:material-download:{ .lg .middle } [Download Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

### Azure Developer CLI
The Azure Developer CLI (azd) is a command-line tool designed to accelerate the time it takes to get started on Azure. It's particularly useful for Azure development tasks.

:material-download:{ .lg .middle } [Download Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)

### Visual Studio Code Extensions

After installing Visual Studio Code, please install the following extensions to enahnce your development experience with working with this solution.

| Name | Recommendation | Description |
|------|----------------|-------------|
| [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) | Required | Allows you to send HTTP requests and view responses directly within VS Code |
| [Bicep](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep) | Required | Provides language support for Bicep, a domain-specific language for deploying Azure resources |
| [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python) | Optional | Adds rich support for the Python language, including features like IntelliSense and debugging |
| [Java Extension Pack](https://marketplace.visualstudio.com/items?itemName=vscjava.vscode-java-pack) | Optional | A collection of popular extensions for Java development in VS Code |

