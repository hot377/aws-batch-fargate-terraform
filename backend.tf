/* #コメントアウトしてapplyして、S3作成後に外してapplyする。
terraform {
  backend "s3" {
    bucket = "<YOUR_TFSTATE_BUCKET_NAME>" # backendブロックでは変数を使えないため直接書き換える
    key    = "dev"           
    region = "ap-northeast-1"                  
    use_lockfile = true
    encrypt = true                             
  }
}
*/
resource "aws_s3_bucket" "tfstate" {
  bucket = var.tfstate_bucket_name
  
  # 検証用なので、中身があっても強制削除できるように設定
  force_destroy = true 
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.tfstate.id # 名前を統一
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.tfstate.id # 名前を統一
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}