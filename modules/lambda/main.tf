data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/function.py"
  output_path = "${path.module}/src/lambda_function.zip"
}

resource "aws_lambda_function" "this" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.environment}-fargate-batch-function"
  role          = var.lambda_exec_role_arn
  handler       = "index.lambda_handler" # ファイル名.関数名
  runtime       = "python3.14"
  timeout       = 30

  environment {
    variables = {
      BATCH_JOB_QUEUE_ARN      = var.batch_job_queue_arn
      BATCH_JOB_DEFINITION_ARN = var.batch_job_definition_arn
      OUTPUT_BUCKET            = var.output_bucket_name
    }
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn 
}