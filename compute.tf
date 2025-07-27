resource "aws_launch_template" "app_template" {
  name_prefix   = "app-template-"
  image_id      = "ami-0c623b18596168e93" # Amazon Linux 2 para sa-east-1 (verificar a mais recente)
  instance_type = "t2.micro"

  // Anexa o perfil do IAM que criamos
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  // Anexa o Security Group das instâncias
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  // Script de exemplo que roda na inicialização
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Olá do Terraform! Servidor: $(hostname -f)</h1>" > /var/www/html/index.html
              EOF
  )
}

resource "aws_lb" "app_lb" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id] // ALB na rede pública
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check { path = "/" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name               = "app-asg"
  desired_capacity   = 4 // Mínimo de 4 instâncias
  min_size           = 4
  max_size           = 8 // Permite escalar até 8
  
  // As instâncias agora são criadas nas sub-redes PRIVADAS
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.app_tg.arn]
}