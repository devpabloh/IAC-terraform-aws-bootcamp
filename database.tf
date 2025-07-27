// Cria um grupo de sub-redes para o RDS, dizendo em quais redes privadas ele pode operar
resource "aws_db_subnet_group" "db_subnet_group" {
    name       = "db-subnet-group"
    subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    tags = {
        Name = "Meu DB Subnet Group"
    }
}

// Cria a instância do banco de dados RDS
resource "aws_db_instance" "postgres_db" {
    identifier           = "meu-banco-postgres"
    instance_class       = "db.t3.micro"
    allocated_storage    = 20
    engine               = "postgres"
    engine_version       = "15.3"
    username             = "admin"
    password             = var.db_password 
    db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
    vpc_security_group_ids = [aws_security_group.db_sg.id]
    multi_az             = true             // Configurando a ativação dá alta disponibilidade
    skip_final_snapshot  = true
}