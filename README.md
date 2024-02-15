# Overview

This is the terraform repo for the Equal Vote Coalition. It's currently used to deploy a Kubernetes cluster to Azure.

# Onboarding

For full onboarding follow [our documentation](https://equal-vote.github.io/star-server/contributions/Infrastructure/2_devops_local_setup.html)

# Bootstrapping

Based on:
* https://developer.hashicorp.com/terraform/tutorials/azure-get-started/azure-build
* https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli
* https://github.com/Azure-Samples/terraform-github-actions/blob/main/main.tf

1. Create Service Principal that will be used by GitHub Actions:
    ```
    export SUBSCRIPTION_ID="your Azure subscription ID"
    az ad sp create-for-rbac --name terraform --role="Contributor" --scopes="/subscriptions/$SUBSCRIPTION_ID"
    ```
1. Add these variables [here](https://github.com/Equal-Vote/terraform/settings/variables/actions):
    ```
    ARM_CLIENT_ID="set this to the the appId value"
    ARM_SUBSCRIPTION_ID="your Azure subscription ID"
    ARM_TENANT_ID="set this to the tenant value"
    ```
1. Add ARM_CLIENT_SECRETthese secrets [here](https://github.com/Equal-Vote/terraform/settings/secrets/actions):
    ```
    ARM_CLIENT_SECRET="set this to the password value"
    ```
1. Create Azure resource group, storage account, and storage container that will be used to store Terraform state:
    ```
    RESOURCE_GROUP_NAME=tfstate
    STORAGE_ACCOUNT_NAME=equalvoteterraform
    CONTAINER_NAME=tfstate

    # Create resource group
    az group create --name $RESOURCE_GROUP_NAME --location westus2

    # Create storage account
    az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

    # Create blob container
    az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME
    ```
1. Display the ARM_ACCESS_KEY:
    ```
    az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv
    ```
1. Add ARM_ACCESS_KEY as a secret [here](https://github.com/Equal-Vote/terraform/settings/secrets/actions).

# Connecting to the cluster

```
az aks get-credentials --resource-group equalvote --name equalvote
```

# Updating

terraform init -upgrade
Should see changes to .terraform.lock.hcl.
Commit them.

# TODO

Should we be using Managed Identity instead of Service Principal?
https://arnav.au/2023/09/08/azure-managed-identity-vs-service-principal/
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/managed_service_identity

