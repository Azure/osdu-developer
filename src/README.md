# OSDU Source Code Directory

Welcome to the OSDU Source Code directory! This directory is structured to help you easily clone down the OSDU services and related repositories using the `gita` command.

> It is recommended to not do this in a Remote Container or Github Codespace.  Working with OSDU services is best suited for direct execution on a local machine.

## Directory Structure

The directory is organized into the following structure:

```
src/
├── lib
├── core
└── reference
```

### Explanation:
- **lib**: This directory is designated for libraries and shared components.
- **core**: This directory contains the core OSDU services repositories.
- **reference**: This directory holds reference implementations and example projects.

## Cloning OSDU Services

To clone the OSDU services into this directory structure, you can use the `gita` command. `gita` is a tool that simplifies the management of multiple Git repositories. If you haven't already installed `gita`, you can do so by following these instructions:

### Installing `gita`

To install `gita`, use pip:

```bash
pip install gita
```

For more details on `gita`, please visit the official [gita documentation](https://github.com/nosarthur/gita).

### Using `gita` to Clone Repositories

Once `gita` is installed, navigate to the appropriate subdirectory (e.g., `lib`, `core`, or `reference`) and use the `gita` command to clone down the required OSDU services and auto create a group.

Here's an example:

```bash
# Clone OSDU Repositories
(cd src/lib && gita clone -f repos)
(cd src/core && gita clone -f repos)
(cd src/reference && gita clone -f repos)

# Create the Groups
gita add -a lib && gita group rename lib osdu-lib
gita add -a core && gita group rename core osdu-core
gita add -a reference && gita group rename reference osdu-reference

# Set the Auto Context
gita context auto

# Switch to the release branch and pull code
gita super release/0.27
gita pull
```

Repeat the above steps for each directory, ensuring they are placed in the correct subdirectory.

