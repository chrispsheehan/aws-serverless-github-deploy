resource "aws_s3_bucket" "lambda" {
  bucket        = var.lambda_bucket
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "lambda" {
  depends_on = [aws_s3_bucket.lambda]
  bucket     = aws_s3_bucket.lambda.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "delete_old_files" {
  count = var.s3_expiration_days > 0 ? 1 : 0

  bucket = aws_s3_bucket.lambda.id

  rule {
    id     = "delete-expired-objects"
    status = "Enabled"

    expiration {
      days = var.s3_expiration_days
    }
  }
}
