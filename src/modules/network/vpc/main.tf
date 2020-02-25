resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr_range
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.main_vpc.id

  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    action     = "allow"
    rule_no    = 100
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    action     = "allow"
    rule_no    = 100
    cidr_block = "0.0.0.0/0"
  }

  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    action     = "deny"
    rule_no    = 1000
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    action     = "deny"
    rule_no    = 1000
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "main_acl"
  }
}