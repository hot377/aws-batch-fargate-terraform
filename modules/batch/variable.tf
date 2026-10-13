variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type =  list(string)
}

variable "batch_exec_role_arn" {
  type = string
}

variable "batch_task_role_arn" {
  type = string
}

variable "security_group_ids" {
  type =  list(string)
}

variable "image_url" {
  type = string
}