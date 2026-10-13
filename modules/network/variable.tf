variable "vpc_name" {
  description = "VPCの名前"
  type        = string
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
}


variable "private_subnets" {
  description = "Privateサブネット定義"
  type = map(object({
    az   = string
    cidr = string
  }))
}

variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}