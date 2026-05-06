#!/usr/bin/env bash
# Discovers all PVC-backed Azure managed disks and tags them for backup.
# Generates a tfvars file with disk IDs for use by Terraform.

set -euo pipefail

RESOURCE_GROUP="${1:?Resource group required}"
CLUSTER_NAME="${2:?Cluster name required}"
OUTPUT_FILE="${3:-tagged-disks.tfvars}"

# Get the AKS node resource group (where managed disks live)
NODE_RG=$(az aks show -g "$RESOURCE_GROUP" -n "$CLUSTER_NAME" --query nodeResourceGroup -o tsv)

if [ -z "$NODE_RG" ]; then
  echo "ERROR: Could not determine node resource group" >&2
  exit 1
fi

# Get all PVC-backed managed disks (CSI driver names them with kubernetes-dynamic-pvc-* prefix)
DISK_IDS=$(az disk list -g "$NODE_RG" \
  --query "[?starts_with(name, 'kubernetes-dynamic-pvc-')].id" \
  -o tsv)

if [ -z "$DISK_IDS" ]; then
  echo "ERROR: No PVC-backed disks found in $NODE_RG" >&2
  exit 1
fi

TAGGED_IDS=()

while IFS= read -r disk_id; do
  if [ -z "$disk_id" ]; then continue; fi

  az disk update --ids "$disk_id" --tags backup=true > /dev/null 2>&1
  TAGGED_IDS+=("$disk_id")
done <<< "$DISK_IDS"

if [ ${#TAGGED_IDS[@]} -eq 0 ]; then
  echo "ERROR: No disks were tagged" >&2
  exit 1
fi

# Generate tfvars file
{
  echo "disk_ids = ["
  for id in "${TAGGED_IDS[@]}"; do
    echo "  \"$id\","
  done
  echo "]"
} > "$OUTPUT_FILE"

echo "Generated $OUTPUT_FILE with ${#TAGGED_IDS[@]} disk ID(s)" >&2
