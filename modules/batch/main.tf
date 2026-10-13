resource "aws_batch_compute_environment" "this" {
  name = "${var.environment}-fargete-batch-env"
  type                     = "MANAGED"
  state                    = "ENABLED"

  compute_resources {
    type = "FARGATE"
    max_vcpus = 1
    
    
    # ネットワーク設定
    subnets            = var.private_subnet_ids
    security_group_ids = var.security_group_ids
  }
}

resource "aws_batch_job_queue" "this" {
  name     = "${var.environment}-fargate-batch-queue"
  state    = "ENABLED"
  
  priority = 1
  compute_environment_order {
    order       = 1
    compute_environment = aws_batch_compute_environment.this.arn
  }
}

resource "aws_batch_job_definition" "this" {
  name = "${var.environment}-batch-job-def"
  type = "container"
  
  platform_capabilities = ["FARGATE"]
  
  container_properties = jsonencode({
  image = var.image_url
    
    # 実行ロール（ECS/Batchインフラ用）
    executionRoleArn = var.batch_exec_role_arn
    # タスクロール（アプリのS3操作用）
    jobRoleArn       = var.batch_task_role_arn

    fargatePlatformConfiguration = {
      platform_version = "LATEST"
    }

    resourceRequirements = [
      { 
        type = "VCPU"
        value = "0.25" 
      },
      { type = "MEMORY" 
        value = "512" 
      }
    ]
  })
}