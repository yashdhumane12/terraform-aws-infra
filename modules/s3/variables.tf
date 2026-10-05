variable "project" { type = string }
variable "environment" { type = string }

variable "bucket_suffix" {
  description = "Suffix for the bucket name (e.g. 'assets', 'backups', 'logs')"
  type        = string
  default     = "assets"
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
