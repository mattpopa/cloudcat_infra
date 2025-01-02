resource "aws_lb" "hosting_alb" {
  name               = "hosting-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.dev_vpc.public_subnets

  enable_deletion_protection = false
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.hosting_alb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = module.acm.acm_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Default action for unmatched hosts"
      status_code  = "404"
    }
  }
}

## Target group

resource "aws_lb_target_group" "wordpress_tg" {
  name        = "wordpress-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.dev_vpc.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "wordpress_attachment" {
  target_group_arn = aws_lb_target_group.wordpress_tg.arn
  target_id        = aws_instance.dev4.id
  port             = 80
}

## ALB host routing

resource "aws_lb_listener_rule" "wordpress_host_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 100

  condition {
    host_header {
      values = ["dev4.${data.aws_route53_zone.base.name}"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_tg.arn
  }
}

## ALB SG

resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  vpc_id      = module.dev_vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

