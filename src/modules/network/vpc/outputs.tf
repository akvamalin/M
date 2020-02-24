output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "igw_id" {
  value = aws_internet_gateway.internet_gw.id
}