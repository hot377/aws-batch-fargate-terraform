resource "aws_vpc" "this" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.environment}-${var.vpc_name}"
  }
}


resource "aws_subnet" "this" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.environment}-${var.vpc_name}-${each.key}"
}
}

//プライベートルートテーブルを作成
resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.environment}-${var.vpc_name}-private-rtb"
  }
}

//プライベートサブネットをプライベートルートテーブルに関連付ける
resource "aws_route_table_association" "this" {
  for_each = aws_subnet.this

  subnet_id      = each.value.id
  route_table_id = aws_route_table.this.id
}

//S3のVPCエンドポイントを作成
resource "aws_vpc_endpoint" "s3" {
  vpc_id = aws_vpc.this.id
  service_name = "com.amazonaws.ap-northeast-1.s3"
  route_table_ids = [aws_route_table.this.id]
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "${var.environment}-s3-ep"
  }
}

//ECRのエンドポイントを作成
locals {
  ecr_endpoints = ["api","dkr"]
}

resource "aws_vpc_endpoint" "ecr" {
  for_each = toset(local.ecr_endpoints)

  vpc_id = aws_vpc.this.id
  service_name = "com.amazonaws.ap-northeast-1.ecr.${each.key}"
  vpc_endpoint_type = "Interface"
  subnet_ids = values(aws_subnet.this)[*].id
  security_group_ids = [aws_security_group.ecr.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.environment}-ecr-${each.key}-ep"
  }
}


//ECRエンドポイントのセキュリティグループを作成
resource "aws_security_group" "ecr" {
  vpc_id = aws_vpc.this.id
  name = "${var.environment}-ecr-ep-sg"
  
  tags = {
    Name = "${var.environment}-ecr-ep-sg"
  }
}

resource "aws_security_group_rule" "ecr" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = values(aws_subnet.this)[*].cidr_block
  security_group_id = aws_security_group.ecr.id
}

//batchのセキュリティグループ作成
resource "aws_security_group" "batch" {
  vpc_id = aws_vpc.this.id
  name = "${var.environment}-batch-sg"
  
  tags = {
    Name = "${var.environment}-batch-sg"
  }
}

resource "aws_security_group_rule" "batch" {
  type              = "egress"
  from_port         = 443
  to_port = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.batch.id
}