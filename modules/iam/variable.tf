variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "github_repo" {
  type = string
}

variable "job-definition-arn" {
  type = string
}

variable "job-queue-arn" {
  type = string
}

variable "source_s3_bucket" {
  type = string
}