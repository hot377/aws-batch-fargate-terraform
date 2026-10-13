output "source_bucket" {
  value = aws_s3_bucket.source.bucket
}

output "result_bucket" {
  value = aws_s3_bucket.result.bucket
}

output "source_bucket_arn" {
  value = aws_s3_bucket.source.arn 
}

output "result_bucket_arn" {
  value = aws_s3_bucket.result.arn 
}

