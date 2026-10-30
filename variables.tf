variable "node_count" {
  type = number
}

# Every PVC disk that has ever been backed up, including deleted ones. Generated
# append-only by tag-pvc-disks.sh, because removing an entry destroys that
# disk's backup instance and its recovery points.
variable "disk_ids" {
  type    = set(string)
  default = []
}

# The subset of disk_ids that still exists. No default: if it were missing,
# tofu would destroy every disk's backup role assignment.
variable "current_disk_ids" {
  type = set(string)
}
