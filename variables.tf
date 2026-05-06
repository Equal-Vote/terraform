variable "node_count" {
  type = number
}

variable "disk_ids" {
  type    = set(string)
  default = []
}
