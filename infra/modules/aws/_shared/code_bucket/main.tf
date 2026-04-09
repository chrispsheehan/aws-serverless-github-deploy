resource "aws_s3_bucket" "code" {
  bucket        = var.code_bucket
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "code" {
  depends_on = [aws_s3_bucket.code]
  bucket     = aws_s3_bucket.code.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "delete_old_files" {
  count = var.s3_expiration_days > 0 ? 1 : 0

  bucket = aws_s3_bucket.code.id

  rule {
    id     = "delete-expired-objects"
    status = "Enabled"

    expiration {
      days = var.s3_expiration_days
    }
  }
}
