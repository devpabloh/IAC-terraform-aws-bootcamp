/*  O MOLDE DA INSTÂNCIA (Launch Template) */
// vamos definir como cada nova instância será criada pelo Auto Scaling Group.
resource "aws_launch_template" "app_template" {
  name_prefix   = "app-template-"
  image_id      = "ami-0c55b159cbfafe1f0" // Exemplo: Amazon Linux 2 AMI
  instance_type = "t2.micro"             // Definindo tipo de instância 
  security_group_names = [aws_security_group.instance_sg.name]

  // Aqui, instalamos um servidor web simples para teste.
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Olá do Terraform! Servidor: $(hostname -f)</h1>" > /var/www/html/index.html
              EOF
  )

  tags = {
    Name = "app-instance-template"
  }
}

// O GERENTE DE TRÁFEGO (Application Load Balancer)
resource "aws_lb" "app_lb" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id] # Precisa estar nas subnets públicas
}

// definindo o grupo de alvos para onde o ALB enviará tráfego
resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  /* Health Check: O ALB verifica se as instâncias estão saudáveis, se estiverem ele as envia tráfego e se não estiverem ele não envia tráfego. */
  health_check {
    path = "/"
    protocol = "HTTP"
  }
}

// O "ouvinte": escuta na porta 80 e encaminha para o Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

// Aqui estamos garantindo à escalabilidade (Auto Scaling Group)
resource "aws_autoscaling_group" "app_asg" {
  name                      = "app-asg"
  desired_capacity          = 2 # Começa com 2 instâncias
  min_size                  = 2 # Mínimo de 2 instâncias
  max_size                  = 4 # Máximo de 4 instâncias
  vpc_zone_identifier       = [aws_subnet.public_a.id, aws_subnet.public_b.id] # Em quais subnets criar

  // Usa o Launch Template que definimos
  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }

  // estamos anexando as instâncias ao Target Group do Load Balancer
  target_group_arns = [aws_lb_target_group.app_tg.arn]

  # Política de escalabilidade simples baseada em CPU
  # (Esta é a parte que conecta com o CloudWatch)
  # Para um exemplo inicial, vamos omitir a política explícita, mas o ASG já
  # fará o básico: manter o `desired_capacity` e substituir instâncias não-saudáveis.
}

# Para uma escalabilidade real, você adicionaria isso:
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "cpu-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "TargetTrackingScaling"
  
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0 # Tenta manter a média de CPU em 70%
  }
}