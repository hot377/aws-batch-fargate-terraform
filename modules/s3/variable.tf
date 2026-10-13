variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "source_bucket_name" {
  type = string
}

variable "result_bucket_name" {
 type = string 
}

variable "lambda_function_arn" {
 type = string 
}