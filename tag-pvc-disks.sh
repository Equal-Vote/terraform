#!/usr/bin/env bash
# Discovers all PVCs in the cluster and tags the corresponding Azure managed disks.
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

# Get all PVCs
PVC_INFO=$(kubectl get pvc -A -o jsonpath='{range .items[*]}{"namespace="}{.metadata.namespace}{" name="}{.metadata.name}{" volumeName="}{.spec.volumeName}{"\n"}{end}' 2>/dev/null || echo "")

if [ -z "$PVC_INFO" ]; then
  echo "ERROR: No PVCs found" >&2
  exit 1
fi

DISK_IDS=()

while IFS= read -r line; do
  if [ -z "$line" ]; then continue; fi

  NS=$(echo "$line" | sed 's/.*namespace=\([^ ]*\).*/\1/')
  PVC_NAME=$(echo "$line" | sed 's/.*name=\([^ ]*\).*/\1/')
  VOLUME_NAME=$(echo "$line" | sed 's/.*volumeName=\([^ ]*\).*/\1/')

  if [ -z "$VOLUME_NAME" ] || [ "$VOLUME_NAME" = "<none>" ]; then
    echo "WARNING: PVC $NS/$PVC_NAME has no bound volume, skipping" >&2
    continue
  fi

  DISK_ID=$(az disk list -g "$NODE_RG" --query "[?name=='$VOLUME_NAME'].id" -o tsv)

  if [ -z "$DISK_ID" ]; then
    echo "WARNING: Managed disk not found for volume $VOLUME_NAME (PVC $NS/$PVC_NAME)" >&2
    continue
  fi

  az disk update --ids "$DISK_ID" --tags backup=true > /dev/null 2>&1
  echo "Tagged disk: $VOLUME_NAME (PVC: $NS/$PVC_NAME)" >&2

  DISK_IDS+=("$DISK_ID")
done <<< "$PVC_INFO"

if [ ${#DISK_IDS[@]} -eq 0 ]; then
  echo "ERROR: No disks were tagged" >&2
  exit 1
fi

# Generate tfvars file
{
  echo "disk_ids = ["
  for id in "${DISK_IDS[@]}"; do
    echo "  \"$id\","
  done
  echo "]"
} > "$OUTPUT_FILE"

echo "Generated $OUTPUT_FILE with ${#DISK_IDS[@]} disk ID(s)" >&2
