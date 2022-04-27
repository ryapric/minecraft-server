variable "debian_version_id" {
  description = ""
  type        = number
  default     = 11
}

variable "instance_type" {
  description = ""
  type        = string
  default     = "t3a.small" # c5a.large is a cheap, CPU-heavy, 2-core to consider as well
}

variable "world_name" {
  description = ""
  type        = string
}
