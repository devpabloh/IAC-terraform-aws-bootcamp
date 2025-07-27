// Security Group para o Load Balancer (ALB), buscando permitir tráfego HTTP na porta 80 e permitindo que o ALB se comunique com qualquer lugar (egress)
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Permite tráfego HTTP para o ALB"
  vpc_id      = aws_vpc.main.id

  // Regra de entrada: permite tráfego na porta 80 de qualquer lugar
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Regra de saída: permite que o ALB se comunique com qualquer lugar
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Security Group para as instâncias EC2, isso permite que as instâncias recebam tráfego do ALB
resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Permite tráfego do ALB"
  vpc_id      = aws_vpc.main.id

  // Regra de entrada na qual permite tráfego na porta 80 APENAS do Security Group do ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  // Regra de saída na qual permite que as instâncias acessem a internet (ex: para atualizações)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}