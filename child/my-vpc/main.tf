# Create VPC
resource "aws_vpc" "my-vpc" {
  cidr_block          = var.cidr_block
  instance_tenancy    = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.vpc_name}-${var.environment}"
  }
}

# Create public and private subnet
resource "aws_subnet" "subnet" {
  count                = 3
  vpc_id               = aws_vpc.my-vpc.id
  cidr_block           = cidrsubnet(var.cidr_block, 8, count.index * 10)
  map_public_ip_on_launch = true
  availability_zone    = element(data.aws_availability_zones.available-zones.names, count.index)

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "vpc-gt" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "itg"
  }
}

# Create route table
resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "route-table"
  }
}

# Create route table association
resource "aws_route_table_association" "route-table-ass" {
  count         = 3
  subnet_id     = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.route-table.id
}

# Edit the routes of the three subnets
resource "aws_route" "rt" {
  route_table_id         = aws_route_table.route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc-gt.id
}
