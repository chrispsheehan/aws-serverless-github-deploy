data "aws_iam_policy_document" "cloudfront_oac" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = local.caching_optimized_id
}

data "aws_cloudfront_origin_request_policy" "origin_request" {
  name = local.origin_request_policy_id
}

data "aws_cloudfront_response_headers_policy" "response_headers" {
  name = local.response_headers_policy_id
}

data "aws_caller_identity" "current" {}
