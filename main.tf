// moduleのvariableの名前 = module.ディレクトリ名.outout名

//modules/networkを呼び出す
module "network" {
  source = "./modules/network"

  vpc_name = var.vpc_name
  environment = var.environment
  vpc_cidr = "10.0.0.0/16"

  private_subnets = {
    "private-1a" = {
      az   = "ap-northeast-1a"
      cidr = "10.0.10.0/24"
    }
    "private-1c" = {
      az   = "ap-northeast-1c"
      cidr = "10.0.11.0/24"
    }

    "private-1d" = {
      az   = "ap-northeast-1d"
      cidr = "10.0.12.0/24"
    }
  }
}

module "iam" {
  source = "./modules/iam"

  environment = var.environment
  github_repo = var.github_repo
  job-definition-arn = module.batch.job_definition_arn
  job-queue-arn = module.batch.job_queue_arn
  source_s3_bucket = module.s3.source_bucket # module.s3.アウトプット名

}

module "s3" {
  source = "./modules/s3"

  environment = var.environment
  source_bucket_name = var.source_bucket_name
  result_bucket_name = var.result_bucket_name
  lambda_function_arn = module.lambda.lambda_function_arn
  
}


module "ecr" {
  source = "./modules/ecr"

  ecr_repo_name = var.ecr_repo_name
  environment = var.environment
}

module "lambda" {
  source = "./modules/lambda"

  environment              = var.environment
  lambda_exec_role_arn     = module.iam.lambda_exec_role_arn
  
  # 他のモジュールからの「橋渡し」
  batch_job_queue_arn      = module.batch.job_queue_arn
  batch_job_definition_arn = module.batch.job_definition_arn
  output_bucket_name       = module.s3.result_bucket
  
  # S3通知設定で使うためのバケットARN（Permission用）
  s3_bucket_arn            = module.s3.result_bucket_arn 
}

module "batch" {
  source = "./modules/batch"

  environment = var.environment
  vpc_id = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  security_group_ids = [module.network.aws_security_group_batch]
  batch_exec_role_arn = module.iam.batch_exec_role_arn
  batch_task_role_arn = module.iam.batch_task_role_arn
  image_url = module.ecr.repository_url
}
