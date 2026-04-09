### start of static vars set in root.hcl ###
variable "code_bucket" {
  description = "S3 bucket to host build artifacts"
  type        = string
}
### end of static vars set in root.hcl ###

variable "s3_expiration_days" {
  description = "Number of days before objects are deleted (set to 0 to disable)"
  type        = number
  default     = 0
}
