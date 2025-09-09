### start of static vars set in root.hcl ###
variable "lambda_bucket" {
  description = "S3 bucket to host lambda code files"
  type        = string
}
### end of static vars set in root.hcl ###


variable "s3_expiration_days" {
  description = "Number of days before objects are deleted (set to 0 to disable)"
  type        = number
  default     = 0
}
