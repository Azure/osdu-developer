# OSDU Source Code

This section provides comprehensive guidance for working with the community code and integrates automatically with an OSDU™ Personal Instance. The preconfigured `src` directory structure optimizes the organization of repositories to enable efficiency. A personal instance includes generated environment variables to streamline the development process.

!!! tip
    Environment variables can be referenced in IntelliJ with the [EnvFile](https://plugins.jetbrains.com/plugin/7861-envfile) plugin.

!!! warning
    Avoid using containers, always use a local machine when working with OSDU™ source code.


## Overview

The directory is organized into the following structure:


<div class="grid cards" markdown>

-   :material-library:{ .lg .middle } __lib__

    ---

    Libraries and shared components.

-   :material-cube-outline:{ .lg .middle } __core__

    ---

    Core OSDU service repositories.

-   :material-book-open-variant:{ .lg .middle } __reference__

    ---

    Reference and Helper OSDU service repositories.

</div>

## Cloning

To clone the OSDU services into this directory structure, you can use the `gita` command. `gita` is a tool that simplifies the management of multiple Git repositories. If you haven't already installed `gita`, you can do so by following these instructions:

### Installing `gita`

Use pip to install _gita_: `pip install gita`

??? Tip "Learning Opportunity"
    To learn more about this tool and its capabilities, check out the comprehensive [gita documentation](https://github.com/nosarthur/gita) on the official GitHub repository.



### Clone Repositories

Navigate to the appropriate subdirectory (e.g., `lib`, `core`, or `reference`) and use the `gita` command to clone down the required OSDU services and auto create a group.

=== "Bash"

    ```bash
    # Clone OSDU Repositories
    (cd lib && gita clone -f repos)
    (cd core && gita clone -f repos)
    (cd reference && gita clone -f repos)

    # Create the Groups
    gita add -a lib && gita group rename lib osdu-lib
    gita add -a core && gita group rename core osdu-core
    gita add -a reference && gita group rename reference osdu-reference

    # Set the Auto Context
    gita context auto

    # Switch to the release branch and pull code
    gita super switch release/0.27
    gita pull
    ```

=== "Powershell"

    ```pwsh
    # Clone OSDU Repositories
    Push-Location lib; gita clone -f repos; Pop-Location
    Push-Location core; gita clone -f repos; Pop-Location
    Push-Location reference; gita clone -f repos; Pop-Location

    # Create the Groups
    gita add -a lib; gita group rename lib osdu-lib
    gita add -a core; gita group rename core osdu-core
    gita add -a reference; gita group rename reference osdu-reference

    # Set the Auto Context
    gita context auto

    # Switch to the release branch and pull code
    gita super switch release/0.27
    gita pull
    ```






