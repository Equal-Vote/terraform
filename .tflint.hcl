# Providers are pinned to exact versions in the `required_providers` block in
# `main.tf`, so this rule can stay on to keep them that way.
rule "terraform_required_providers" {
  enabled = true
}

# The version is pinned in `.opentofu-version`, because it's used by both [tenv](https://github.com/tofuutils/tenv) and the [setup-opentofu](https://github.com/opentofu/setup-opentofu) GitHub action.
rule "terraform_required_version" {
  enabled = false
}
