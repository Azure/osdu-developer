# Contribution Guide

Some important information to consume about the Repo, before you contribute. There's a lot of info here, so make sure to read it.

## Opportunities to contribute

Start by looking through the [active issues](https://github.com/azure/osdu-developer/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22).

## Action Workflows

Have awareness of the various [workflows](docs/pipelines.md) that run on Push / PR / Schedule.


### Enforced PR Checks

Each has a _Validate job_, that is required to pass before merging to main. PR's tagged with `bug`, that contain changes to bicep or workflow files will need to pass all of the jobs in the relevant workflows before merge is possible.

### PR's from Forks

If you're creating a PR from a fork then we're unable to run the typical actions to ensure quality that the core team are able to use. This is because GitHub prevents Forks from leveraging secrets in this repository. PR's from forks will therefore require comprehensive checking from the core team before merging. Don't be surprised if we change the target branch to a new branch in order to properly test the changes before they hit main.

## Branches

### Feature Branch

For the _most part_ we try to use feature branches to PR to Main

```text
┌─────────────────┐         ┌───────────────┐
│                 │         │               │
│ Feature Branch  ├────────►│     Main      │
│                 │         │               │
└─────────────────┘         └───────────────┘

```

Branch Policies require the Validation stage of our GitHub Action Workflows to successfully run. The Validation stage does an Az Deployment WhatIf and Validation on an Azure Subscription, however later stages in the Actions that actually deploy resources do not run. This is because we've got a high degree of confidence in the Validate/WhatIf capability. We do run the full stage deploys on a weekly basis to give that warm fuzzy feeling. At some point, we'll run these as part of PR to main.

### The Develop Branch

Where there have been significant changes and we want the full gamut of CI testing to be run on real Azure Infrastructure - then the Develop branch is used.
It gives us the nice warm fuzzy feeling before merging into Main.
We anticipate the use of the Develop branch is primarily just for use with Forks.

```text
┌─────────────────┐         ┌─────────────┐       ┌────────────┐
│                 │         │             │       │            │
│ Feature Branch  ├────────►│   Develop   ├──────►│    Main    │
│                 │         │             │       │            │
└─────────────────┘         └─────────────┘       └────────────┘
                                  ▲
┌─────────────────┐               │
│                 │               │
│ Feature Branch  ├───────────────┘
│                 │
└─────────────────┘

```