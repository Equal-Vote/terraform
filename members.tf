# Membership of the DevOps and Developers AAD groups (defined in main.tf).
# Members are looked up by UPN; resource labels document each person.

# === DevOps ===

data "azuread_user" "jackson_loper" {
  user_principal_name = "jackson@starvoting.onmicrosoft.com"
}

resource "azuread_group_member" "jackson_loper_devops" {
  group_object_id  = azuread_group.devops.object_id
  member_object_id = data.azuread_user.jackson_loper.object_id
}

# === Developers ===
# (none yet)
