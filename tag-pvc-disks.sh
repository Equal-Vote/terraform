#!/usr/bin/env bash
# Discovers all PVC-backed Azure managed disks.
# Generates a tfvars file with disk IDs for use by Terraform.

set -Eeuo pipefail

RESOURCE_GROUP="${1:?Resource group required}"
CLUSTER_NAME="${2:?Cluster name required}"
OUTPUT_FILE="${3:-tagged-disks.tfvars}"

# Get the AKS node resource group (where managed disks live)
NODE_RG=$(az aks show -g "$RESOURCE_GROUP" -n "$CLUSTER_NAME" --query nodeResourceGroup -o tsv)

if [ -z "$NODE_RG" ]; then
  echo "ERROR: Could not determine node resource group" >&2
  exit 1
fi

# Get all PVC-backed managed disks
DISK_IDS=$(az disk list -g "$NODE_RG" \
  --query "[?starts_with(name, 'pvc-')].id" \
  -o tsv)

if [ -z "$DISK_IDS" ]; then
  echo "ERROR: No PVC-backed disks found in $NODE_RG" >&2
  exit 1
fi

# Generate tfvars file
{
  echo "disk_ids = ["
  while IFS= read -r disk_id; do
    if [ -n "$disk_id" ]; then
      echo "  \"$disk_id\","
    fi
  done <<< "$DISK_IDS"
  echo "]"
} > "$OUTPUT_FILE"

echo "Generated $OUTPUT_FILE" >&2
