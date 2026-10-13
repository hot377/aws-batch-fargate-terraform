resource "aws_s3_bucket" "source" {
  bucket = var.source_bucket_name

  tags = {
    Name        = var.source_bucket_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_notification" "source" {
  bucket = var.source_bucket_name

  lambda_function {
    lambda_function_arn = var.lambda_function_arn
    events              = ["s3:ObjectCreated:Put"]
    filter_prefix       = "*"
    filter_suffix       = "*"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}



resource "aws_s3_bucket" "result" {
  bucket = var.result_bucket_name

  tags = {
    Name        = var.result_bucket_name
    Environment = var.environment
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn # 以前定義した変数
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source.arn # ソースバケットのARN
}