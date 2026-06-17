# AGENTS.md — Equal Vote Terraform

## Toolchain

- Use `tofu` not `terraform` — OpenTofu 1.11 (pinned in `.opentofu-version`).
- State is in Azure: `rg=tfstate`, `sa=equalvoteterraform`, `container=tfstate`.
- Providers: azurerm, azuread, kubernetes, external — all from `registry.opentofu.org`.

## Commands

- Format check: `tofu fmt -recursive -check`
- Init: `tofu init`
- Validate: `tofu validate -no-color`
- Plan: `tofu plan -no-color -input=false -out=plan.file`
- Apply: `tofu apply -no-color -input=false plan.file`
- Lint: `tflint` (config: `.tflint.hcl`)
- Upgrade providers: run `./upgrade.sh` (deletes lockfile, comments versions, runs `tofu init -upgrade`, then manually uncomment + update pins)
- Cluster access: `az aks get-credentials --resource-group equalvote --name equalvote`

## CI

- `.github/workflows/opentofu.yml`: PR → `fmt`→`init`→`validate`→`plan` (comment on PR). Push to main → same + `apply`.
- Plugin cache configured (`TF_PLUGIN_CACHE_DIR`).
- Paths ignored: `tag-pvc-disks.sh` (changes to it don't trigger infra CI).

## Architecture

- Single AKS cluster `equalvote` in West US 2, Kubernetes 1.31, OIDC + Workload Identity, local accounts disabled, Azure AD RBAC.
- Azure AD groups: `DevOps` (cluster admin RBAC), `Developers` (cluster user).
- DNS zones: `sandbox.star.vote`, `prod.equal.vote`, `dev.equal.vote`.
- Two key vaults: `equalvote` (SOPS key — access policies use hardcoded SP object_id, not data lookup) and `equalvote-argocd` (imported via `imports.tf`).
- Loki workload identity: `system:serviceaccount:loki:loki` federated with Azure managed identity.
- Backup vault: daily disk snapshots, retention 7d daily / 28d weekly / 180d monthly.
- `.sops.yaml` configured for Azure Key Vault but marked "not in use yet".

## Auto-generated files

- `tagged-disks.auto.tfvars`: auto-loaded by OpenTofu (`.auto.tfvars` naming). Generated weekly by `tag-pvc-disks.yml` via `tag-pvc-disks.sh equalvote equalvote tagged-disks.auto.tfvars`.
- That workflow uses `GITHUB_TOKEN`, so its PRs don't trigger `opentofu.yml` (documented limitation — needs PAT to fix).

## Known quirks

- `kubernetes` provider block in `rbac.tf` is commented out — not configured despite being in `required_providers`.
- `imports.tf` uses `import` blocks for 3 existing ArgoCD resources (key vault, managed identity, key vault key).
- The `terraform` provider alias and the `azuread` provider are used without explicit configuration in `provider` blocks (no `alias` needed).
