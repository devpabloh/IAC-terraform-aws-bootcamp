// Exibe o DNS público do nosso Load Balancer
output "alb_dns_name" {
  description = "O endereço DNS do Application Load Balancer"
  value       = aws_lb.app_lb.dns_name
}