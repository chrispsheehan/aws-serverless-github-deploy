### start of static vars set in root.hcl ###
variable "project_name" {
  type = string
}

variable "ecr_repository_name" {
  type = string
}
### end of static vars set in root.hcl ###

variable "allowed_read_aws_account_ids" {
  description = "AWS Account allowed to pull from ci ecr"
  type        = list(string)
}

variable "scan_on_push" {
  type    = bool
  default = true
}

variable "force_delete" {
  type    = bool
  default = false
}

variable "image_expiration_days" {
  description = "Number of days before images are deleted (set to 0 to disable)"
  type        = number
  default     = 0
}
