# Brewfile for Equal-Vote/terraform
#
# Installs every CLI tool used or referenced by this repo.
# Usage: brew bundle

# Azure CLI (`az`) - bootstrapping (service principal, resource group, state
# storage), `az aks get-credentials`, and tag-pvc-disks.sh
brew "azure-cli"

# tenv - version manager that installs/pins OpenTofu (`tofu`) from
# .opentofu-version, keeping local runs locked to the same version as CI.
# Do NOT install opentofu directly.
brew "tenv"

# git - committing .terraform.lock.hcl changes and the GitOps workflow
brew "git"

# kubectl - using the cluster after `az aks get-credentials` writes the kubeconfig
brew "kubernetes-cli"

# tflint - the lint step documented in AGENTS.md (config: .tflint.hcl)
brew "tflint"

# gh - opens the tagged-disks PR in .github/workflows/tag-pvc-disks.yml
brew "gh"
