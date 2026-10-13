# 実行中のAWSアカウントIDを取得
data "aws_caller_identity" "current" {}

# AWS Batch 実行ロール
resource "aws_iam_role" "batch_exec" {
  name = "${var.environment}-batch-exec-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })
}

# Batch実行ロールにアタッチするポリシー
resource "aws_iam_role_policy_attachment" "name" {
  role = aws_iam_role.batch_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# Batchタスクロール
resource "aws_iam_role" "batch_task" {
  name = "${var.environment}-batch-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Batchタスクロールのポリシー
resource "aws_iam_role_policy_attachment" "s3full" {
  role = aws_iam_role.batch_task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# 5. Lambda 実行ロール (Batchの起動とS3読み込み用)
resource "aws_iam_role" "lambda_exec" {
  name = "${var.environment}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# lamdaにアタッチするポリシー
resource "aws_iam_role_policy_attachment" "s3full_lamda" {
  role = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lamda" {
  name = "${var.environment}-lambda-exec-batch-policy"
  role = aws_iam_role.lambda_exec.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "batch:SubmitJob"
            ],
            "Resource": [# batchモジュールから変数でもってくる
                "arn:aws:batch:ap-northeast-1:${data.aws_caller_identity.current.account_id}:job-definition/handson:2",
                "arn:aws:batch:ap-northeast-1:${data.aws_caller_identity.current.account_id}:job-queue/handon",
                "${var.job-definition-arn}",
                "${var.job-queue-arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::${var.source_s3_bucket}/*"
        }
    ]
})
}

