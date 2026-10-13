output "vpc_id" {
  value = aws_vpc.this.id
}


output "private_subnet_ids" {
  value = values(aws_subnet.this)[*].id
}

output "aws_security_group_batch" {
  value = aws_security_group.batch.id
}

