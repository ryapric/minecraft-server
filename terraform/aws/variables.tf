variable "debian_version" {
  description = "Major version number of the Debian OS server host"
  type        = number
  default     = 11
}

variable "edition" {
  description = "Name of the Minecraft edition to deploy, i.e. 'bedrock' or 'java'"
  type        = string

  validation {
    condition     = can(regex("^(bedrock|java)$", var.edition))
    error_message = "Edtion must be on eof 'bedrock' or 'java'"
  }
}

variable "instance_type" {
  description = "AWS instance type"
  type        = string
  default     = "t3a.small" # c5a.large is a cheap, CPU-heavy, 2-core to consider as well
}

# variable "minecraft_version" {
#   description = "Desired (or partial) version string of the server to download. Will default to finding the latest available"
#   type        = string
#   default     = ""
# }

variable "world_name" {
  description = "World name for Minecraft server"
  type        = string
}
