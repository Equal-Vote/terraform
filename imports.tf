import {
  to = azurerm_key_vault.equalvote-argocd
  id = "/subscriptions/86f3145a-48cc-4255-8757-dd3104d15e57/resourceGroups/equalvote/providers/Microsoft.KeyVault/vaults/equalvote-argocd"
}


import {
  to = azurerm_user_assigned_identity.argocd-identity
  id = "/subscriptions/86f3145a-48cc-4255-8757-dd3104d15e57/resourceGroups/equalvote/providers/Microsoft.ManagedIdentity/userAssignedIdentities/argocd"
}

import {
    to = azurerm_key_vault_key.sops-key
    id = "https://equalvote-argocd.vault.azure.net/keys/sops-key/9d7a971e677f4d8a9f2f7adaf349f7ff"
}
