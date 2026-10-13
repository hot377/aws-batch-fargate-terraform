output "lambda_exec_role_arn" {
  value = aws_iam_role.lambda_exec.arn
}

output "batch_exec_role_arn" {
 value =aws_iam_role.batch_exec.arn 
}

output "batch_task_role_arn" {
 value =aws_iam_role.batch_task.arn 
}