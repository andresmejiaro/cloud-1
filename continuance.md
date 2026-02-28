# Continuance

## Communication Preferences

- Teach incrementally. One file or concept at a time.
- Keep each answer under 120 words unless more depth is explicitly requested.
- Prefer explaining the "why" over dumping a full solution.
- Avoid ambiguous file references like `main.tf` without the directory.
- Do not edit files unless explicitly asked.

## Project Split

- `Inception/`: old app stack, reused as payload for Cloud-1 later.
- `Deployment/`: Terraform/Azure deployment work.

## Current Terraform Status

- Root module: `/home/andres/cloud-1/Deployment`
- Child modules started:
  - `/home/andres/cloud-1/Deployment/modules/resource_group`
  - `/home/andres/cloud-1/Deployment/modules/storage`
  - `/home/andres/cloud-1/Deployment/modules/vm`

- `resource_group` module is working.
- Local workflow already succeeded:
  - `terraform init`
  - `terraform plan`
  - `terraform apply`
  - `terraform destroy`

- Verified result:
  - Azure Resource Group was created and visible in the portal.
  - Destroy was considered important to avoid unexpected cost.

## What Was Learned / Agreed

- Terraform mental model:
  - root module = directory where Terraform is run
  - child module = separate directory called with a `module` block
  - separate `.tf` files inside one directory are only organization, not separate modules

- Useful functional analogy:
  - module = function
  - variables = inputs
  - resource blocks = effectful black-box operations
  - outputs = return values

- Workflow agreed:
  1. decide smallest deployable goal
  2. provider
  3. root variables
  4. module inputs/outputs
  5. root wiring
  6. module implementation
  7. outputs
  8. plan/apply

## Auth / Execution Decisions

- Local machine:
  - `terraform` is installed via snap and was working
  - `az` CLI was already installed
  - auth path chosen for local work: `az login`

- Cluster / final environment:
  - likely plan is container + `az login`
  - reason: avoid long-lived secrets / service principal credentials on disk

- Security concern is important:
  - project evaluation penalizes secret leaks heavily
  - preferred auth story is interactive Azure CLI auth when possible

## Azure / Access Decisions

- Teammate was invited and given `Contributor` on the project resource group.
- Resource-group-scoped access was accepted as a practical first step.
- Azure cost surprises already happened once; avoiding idle spend is a priority.

## Current Code State

- Root RG-only path is working.
- VM-related root variables were temporarily commented/trimmed because Terraform was prompting for unused required vars during RG-only testing.
- `resource_group` module:
  - inputs: `name`, `location`
  - outputs: `name`, `location`, `id`

- `vm` module is not done.
- Main current blocker for `vm` is not Terraform syntax but Azure networking requirements.

## VM Module Discussion State

- User started from the Terraform Registry example for `azurerm_linux_virtual_machine`.
- Important conclusion:
  - the example assumes other resources already exist
  - especially `azurerm_network_interface.example.id`
  - so the real next step is minimal Azure networking

- Minimum expected Azure pieces before SSH works:
  - virtual network
  - subnet
  - public IP
  - network interface
  - rule/path allowing port `22`

- Current preferred VM size direction:
  - `Standard_B2als_v2`
  - chosen mainly for cost sensitivity

- Ubuntu `22.04` image was considered acceptable for the project.

## Cloud-Init / Provisioning Understanding

- Important distinction already covered:
  - Terraform provisions infrastructure
  - `cloud-init` bootstraps inside the VM on first boot

- `cloud-init` is not part of Terraform.
- It is a separate open-source project maintained by Canonical.
- Likely future direction:
  - Terraform creates VM
  - `cloud-init` installs Docker / boots the app stack

## Docs / Learning Conventions Established

- Best place to find basic Terraform resource names:
  - Terraform Registry provider docs, not Azure module repos

- Specifically, the user had accidentally landed on an Azure module repo:
  - `Azure/terraform-azurerm-avm-res-compute-virtualmachine`
  - this was too high-level / confusing for the current stage

- Preferred learning style:
  - use registry examples
  - tweak minimally
  - understand each block before expanding

## Suggested Immediate Next Step

- Continue only with the `vm` module.
- Focus first on the minimum networking needed for SSH.
- Do not jump yet to Docker, disks, TLS, or full Inception bootstrapping.
