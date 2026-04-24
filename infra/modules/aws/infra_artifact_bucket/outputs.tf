output "bucket" {
  description = "S3 bucket that stores infra plan artifacts"
  value       = module.infra_arrifact_bucket.bucket
}
