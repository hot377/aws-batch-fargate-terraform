variable "environment" {
  description = "環境名。各リソースの名前とName/Environmentタグに使われる"
  type        = string
  default     = "dev"
}

variable "vpc_name" {
  description = "VPCの名前。ネットワーク系リソースのNameタグに使われる"
  type        = string
  default     = "fargate-batch-vpc"
}

variable "ecr_repo_name" {
  description = "ECRリポジトリ名。NameタグとGitHub ActionsのECR_REPOSITORYに対応する"
  type        = string
  default     = "fargate-batch-repo"
}

variable "github_repo" {
  description = "GitHubリポジトリ名（owner/repo形式）"
  type        = string
  default     = "hot377/aws-batch-fargate-terraform"
}

variable "source_bucket_name" {
  description = "アクセスログを配置するS3バケット名"
  type        = string
}

variable "result_bucket_name" {
  description = "集計結果を出力するS3バケット名"
  type        = string
}

variable "tfstate_bucket_name" {
  description = "tfstateを保存するS3バケット名"
  type        = string
}
