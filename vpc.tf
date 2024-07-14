resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name        = "subnet-a-igw"
  }
}

/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}
/* NAT */
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(aws_subnet.a.*.id, 0)}"
  depends_on    = [aws_internet_gateway.ig]
  tags = {
    Name = "nat" 
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "public-route-table"
  }
}
resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ig.id}"
}

resource "aws_subnet" "a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet_a"
  }
}

resource "aws_subnet" "b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "subnet_b"
  }
}