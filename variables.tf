variable "db_password" {
    description = "A senha para o banco de dados RDS"
    type        = string
    sensitive   = true # Marca a variável como sensível para não exibi-la nos logs
}