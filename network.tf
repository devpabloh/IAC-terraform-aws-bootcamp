// Criando uma virtual private cloud (VPC) na AWS, que é a nossa rede isolada na nuvem.
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-principal"
  }
}

// criando a primeira subnet pública na Zona de Disponibilidade "sa-east-1a"
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "sa-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-publica-a"
  }
}

// agora vamos criar a segunda subnet pública na Zona de Disponibilidade "sa-east-1b"
resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "sa-east-1b"  # Alterado de "us-east-1b" para "sa-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-publica-b"
  }
}

// criando uma Internet Gateway para permitir acesso à internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw-principal"
  }
}

// Criando uma Tabela de Rotas para direcionar o tráfego da VPC para a internet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"  /* aqui estamos permitindo o tráfego para qualquer destino, que nesse caso é a gateway da internet que definimos anteriormente */ 
    gateway_id = aws_internet_gateway.gw.id
  }
}

// Associa a tabela de rotas às nossas subnets
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}