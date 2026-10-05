variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (Amazon Linux 2)"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
