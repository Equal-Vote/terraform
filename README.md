Based on:
* https://developer.hashicorp.com/terraform/tutorials/azure-get-started/azure-build
* https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli
* https://github.com/Azure-Samples/terraform-github-actions/blob/main/main.tf
* https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app

1. Create Service Principal that will be used by GitHub Actions:
    ```
    export SUBSCRIPTION_ID="%SUB_ID%"
    az ad sp create-for-rbac --name star-server-infra --role="Contributor" --scopes="/subscriptions/$SUBSCRIPTION_ID"
    ```
1. Add ARM env vars to .github/workflows/tf-plan-apply.yml (these values came from the output of the last command):
    ```
    ARM_CLIENT_ID="%CLIENT_ID%"
    ARM_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
    ARM_TENANT_ID="%TENANT_ID%"
    ```
1. Store ARM_CLIENT_SECRET in password manager, and add it as a GitHub Actions secret.
1. Create Azure resource group, storage account, and storage container that will be used to store Terraform state:
    ```
    RESOURCE_GROUP_NAME=tfstate
    STORAGE_ACCOUNT_NAME=starserverinfra
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
1. Add ARM_ACCESS_KEY as a GitHub Actions secret.
1. Add star-server secrets to GitHub actions secret.
    ```
    TF_VAR_DATABASE_URL
    TF_VAR_KEYCLOAK_SECRET
    TF_VAR_PGPASSWORD
    TF_VAR_S3_SECRET
    TF_VAR_SENDGRID_API_KEY
    ```

