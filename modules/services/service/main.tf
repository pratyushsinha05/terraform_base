# Instance Security Group
resource "aws_security_group" "instance" {
  name        = "${var.service_name}-instance-sg"
  description = "Allow ${var.service_name} traffic from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
    description     = "Allow traffic from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB & Target Group
resource "aws_lb" "this" {
  name               = "${var.service_name}-alb"
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets
}

resource "aws_lb_target_group" "this" {
  name     = "${var.service_name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path     = "/healthz"
    interval = 30
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# Launch Template with Base64‐encoded user_data
resource "aws_launch_template" "this" {
  name_prefix   = "${var.service_name}-"
  image_id      = var.instance_ami
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile
  }

  network_interfaces {
    security_groups = [aws_security_group.instance.id]
    subnet_id       = element(var.private_subnets, 0)
  }

  # user_data must be base64‐encoded for Launch Templates
  user_data = base64encode(
    templatefile("${path.module}/user_data.tpl", {
      docker_image_url = var.docker_image_url
      service_name     = var.service_name
      app_port         = var.app_port
    })
  )
}

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  name                      = "${var.service_name}-asg"
  max_size                  = var.max_size
  min_size                  = var.desired_capacity
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.private_subnets

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  target_group_arns         = [aws_lb_target_group.this.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 60
}
