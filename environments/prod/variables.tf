variable "project" {
  type    = string
  default = "myapp"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID for ap-south-1"
  type        = string
  default     = "ami-0f5ee92e2d63afc18"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}
