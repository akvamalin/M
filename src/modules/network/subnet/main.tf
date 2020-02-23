resource "aws_subnet" "public" {
    vpc_id = var.vpc_id
    cidr_block = var.public_subnet_cidr
    availability_zone = var.availability_zone
    map_public_ip_on_launch = true

    tags = {
        Name = format("public %s", var.availability_zone)
    }
}

resource "aws_subnet" "private" {
    vpc_id = var.vpc_id
    cidr_block = var.private_subnet_cidr
    availability_zone = var.availability_zone

    tags = {
        Name = format("private %s", var.availability_zone)
    }
}
 
## NAT Gateway configuration
resource  "aws_eip" "nat_gw_ip" {
    vpc = true
} 

resource "aws_nat_gateway" "nat_gw" {
    allocation_id = aws_eip.nat_gw_ip.id
    subnet_id = aws_subnet.public.id
}

resource "aws_route_table" "nat_gw_routing_table" {
    vpc_id = var.vpc_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = var.igw_id
    }

    tags = {
        Name = format("NAT %s", var.availability_zone)
    }
}

resource "aws_route_table_association" "nat_gw_routes" {
    subnet_id = aws_subnet.private.id
    route_table_id = aws_route_table.private_routing_table.id
}

## Private subnet configuration
resource "aws_route_table" "private_routing_table" {
    vpc_id = var.vpc_id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gw.id
    }

    tags = {
        Name = format("private subnet %s", var.availability_zone)
    }
}

resource "aws_route_table_association" "private_subnet_routes" {
    route_table_id = aws_route_table.private_routing_table.id
    subnet_id = aws_subnet.private.id
}

## Public subnet configuration  
resource "aws_route_table" "public_routing_table" {
    vpc_id = var.vpc_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = var.igw_id
    }

    tags = {
        Name = format("public subnet %s", var.availability_zone)
    }
}

resource "aws_route_table_association" "public_subnet_routes" {
    route_table_id = aws_route_table.public_routing_table.id
    subnet_id = aws_subnet.public.id
}
