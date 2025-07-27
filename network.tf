// network.tf

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-principal"
  }
}

//  REDE PÚBLICA 
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "sa-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "subnet-publica-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "sa-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "subnet-publica-b" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "igw-principal" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "rt-publica" }
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}


//  REDE PRIVADA E NAT GATEWAY 
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "subnet-privada-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "sa-east-1b"
  tags              = { Name = "subnet-privada-b" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "eip-nat" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id // lembrando que o NAT Gateway precisa morar na rede pública, para acessar a internet
  depends_on    = [aws_internet_gateway.gw]
  tags          = { Name = "nat-gateway" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "rt-privada" }
}

resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}