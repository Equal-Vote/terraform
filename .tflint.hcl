# Our providers are pinned in `.terraform.lock.hcl`
rule "terraform_required_providers" {
  enabled = false
}

# The version is pinned in `.opentofu-version`, because it's used by both [tenv](https://github.com/tofuutils/tenv) and the [setup-opentofu](https://github.com/opentofu/setup-opentofu) GitHub action.
rule "terraform_required_version" {
  enabled = false
}
