#!/usr/bin/env bash
# Discovers all PVC-backed Azure managed disks.
# Generates a tfvars file with disk IDs for use by Terraform.
#
# The list is append-only: disks already in OUTPUT_FILE are kept even after
# they are deleted. Dropping a disk from the list makes tofu destroy its backup
# instance, which deletes its recovery points -- the backups we need most once
# a PVC and its disk are gone. Remove entries by hand once their retention has
# expired.

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

# Get all PVC-backed managed disks, with the PVC each was created for. The CSI
# driver tags every disk it provisions with the PVC's namespace and name.
DISKS=$(az disk list -g "$NODE_RG" \
  --query "[?starts_with(name, 'pvc-')].[id, tags.\"kubernetes.io-created-for-pvc-namespace\", tags.\"kubernetes.io-created-for-pvc-name\"]" \
  -o tsv)

if [ -z "$DISKS" ]; then
  echo "ERROR: No PVC-backed disks found in $NODE_RG" >&2
  exit 1
fi

# "namespace/pvc" for each disk ID, written next to the ID in the tfvars file.
# Once a disk is deleted its tags are gone, so this comment is the only record
# of which PVC a backup instance (named after the disk) belonged to.
declare -A LABELS

# Merge with the disks already in the file. Only the disk_ids list is read
# back; current_disk_ids is rebuilt from scratch every run.
EXISTING_IDS=""
if [ -f "$OUTPUT_FILE" ]; then
  while IFS= read -r line; do
    disk_id=$(grep -o '"/subscriptions/[^"]*"' <<< "$line" | tr -d '"') || continue
    EXISTING_IDS+="$disk_id"$'\n'
    if [[ "$line" == *"# "* ]]; then
      LABELS["$disk_id"]="${line#*# }"
    fi
  done < <(sed -n '/^disk_ids = \[/,/^\]/p' "$OUTPUT_FILE")
fi

CURRENT_IDS=""
while IFS=$'\t' read -r disk_id pvc_namespace pvc_name; do
  [ -n "$disk_id" ] || continue
  CURRENT_IDS+="$disk_id"$'\n'
  if [ -n "$pvc_namespace" ] && [ "$pvc_namespace" != "None" ]; then
    LABELS["$disk_id"]="$pvc_namespace/$pvc_name"
  fi
done <<< "$DISKS"

CURRENT_IDS=$(printf '%s' "$CURRENT_IDS" | LC_ALL=C sort -u)
ALL_IDS=$(printf '%s%s\n' "$EXISTING_IDS" "$CURRENT_IDS" | sed '/^$/d' | LC_ALL=C sort -u)

print_list() {
  echo "$1 = ["
  while IFS= read -r disk_id; do
    if [ -n "$disk_id" ]; then
      if [ -n "${LABELS[$disk_id]:-}" ]; then
        echo "  \"$disk_id\", # ${LABELS[$disk_id]}"
      else
        echo "  \"$disk_id\","
      fi
    fi
  done <<< "$2"
  echo "]"
}

# Generate tfvars file
{
  # Every disk ever seen, including deleted ones. Drives the backup instances.
  print_list disk_ids "$ALL_IDS"
  echo
  # Disks that exist right now. Drives the role assignments, which Azure
  # deletes along with the disk and which can't be created on a missing one.
  print_list current_disk_ids "$CURRENT_IDS"
} > "$OUTPUT_FILE"

echo "Generated $OUTPUT_FILE" >&2
