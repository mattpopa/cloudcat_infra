resource "aws_lb" "hosting_alb" {
  name               = "hosting-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.dev_vpc.public_subnets

  enable_deletion_protection = false
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.hosting_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.hosting_alb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn = module.acm.acm_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Default action for unmatched hosts"
      status_code  = "404"
    }
  }
}

# Adding additional ACM certificate for host1
resource "aws_lb_listener_certificate" "host1_certificate" {
  listener_arn    = aws_lb_listener.https_listener.arn
  certificate_arn = module.host1.acm_certificate_arn
}

# Adding additional ACM certificate for host2
resource "aws_lb_listener_certificate" "host2_certificate" {
  listener_arn    = aws_lb_listener.https_listener.arn
  certificate_arn = module.host2.acm_certificate_arn
}

# Rule to redirect www to non-www
resource "aws_lb_listener_rule" "redirect_www_to_non_www" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 50

  condition {
    host_header {
      values = ["www.${local.host1}"]
    }
  }

  action {
    type = "redirect"
    redirect {
      host        = local.host1
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Rule to redirect www to non-www
resource "aws_lb_listener_rule" "redirect_host2_www_to_non_www" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 51

  condition {
    host_header {
      values = ["www.${local.host2}"]
    }
  }

  action {
    type = "redirect"
    redirect {
      host        = local.host2
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

## Target Groups

# Target group for dev4
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

#resource "aws_lb_target_group_attachment" "wordpress_attachment" {
#  target_group_arn = aws_lb_target_group.wordpress_tg.arn
#  target_id        = aws_instance.dev4.id
#  port             = 80
#}

# Target group for host1
resource "aws_lb_target_group" "host1_tg" {
  name        = "host1-target-group"
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

resource "aws_lb_target_group_attachment" "host1_attachment" {
  target_group_arn = aws_lb_target_group.host1_tg.arn
  target_id        = aws_instance.host1.id
  port             = 80
}

# Target group for host2
resource "aws_lb_target_group" "host2_tg" {
  name        = "host2-target-group"
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

resource "aws_lb_target_group_attachment" "hos2_attachment" {
  target_group_arn = aws_lb_target_group.host2_tg.arn
  target_id        = aws_instance.host2.id
  port             = 80
}

## Listener Rules

# Rule for dev4
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

# Rule for host1
resource "aws_lb_listener_rule" "host1_host_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 200

  condition {
    host_header {
      values = [local.host1]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.host1_tg.arn
  }
}

# Rule for host2
resource "aws_lb_listener_rule" "host2_host_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 201

  condition {
    host_header {
      values = [local.host2]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.host2_tg.arn
  }
}

## ALB Security Group

resource "aws_security_group" "alb_sg" {
  name   = "alb-security-group"
  vpc_id = module.dev_vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
