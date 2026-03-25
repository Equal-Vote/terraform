# provider "kubernetes" {
#   host                   = azurerm_kubernetes_cluster.equalvote.kube_config[0].host
#   client_certificate     = base64decode(azurerm_kubernetes_cluster.equalvote.kube_config[0].client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.equalvote.kube_config[0].client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.equalvote.kube_config[0].cluster_ca_certificate)
# }
#
# resource "kubernetes_cluster_role_binding_v1" "devops_cluster_admin" {
#   metadata {
#     name = "devops-cluster-admin"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }
#   subject {
#     kind      = "Group"
#     name      = azuread_group.devops.object_id
#     api_group = "rbac.authorization.k8s.io"
#   }
# }
#
# resource "kubernetes_cluster_role_binding_v1" "developers_view" {
#   metadata {
#     name = "developers-view"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "view"
#   }
#   subject {
#     kind      = "Group"
#     name      = azuread_group.developers.object_id
#     api_group = "rbac.authorization.k8s.io"
#   }
# }
