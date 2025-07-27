/* Aqui estou definindo o provedor que irei utilizar que no caso é a AWS e a região que será utilizada, eu optei por utilizar a região de São Paulo (sa-east-1) devido à baixa latência e questões relacionadas à LGPD (Lei Geral de Proteção de Dados). */
provider "aws"{
    region = "sa-east-1" 
}

/* Aqui estou configurando o Terraform para utilizar o provedor AWS e especificando a versão do provedor que será utilizada, que nesse caso é a versão 5.0 */
terraform{
    required_providers {
      aws = {
        source = "hashicorp/aws" 
        version = "~> 5.0" 
      }
    }
}