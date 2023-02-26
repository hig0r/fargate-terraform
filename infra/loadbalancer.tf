resource "aws_lb" "this" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.http.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_security_group" "http" {
  vpc_id = aws_vpc.this.id

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
  }

  egress {
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    from_port        = 0
    to_port          = 0
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb_target_group" "this" {
  vpc_id = aws_vpc.this.id

  protocol    = "HTTP"
  target_type = "ip"
  port        = 80
  health_check {
    interval            = 30
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 4
    unhealthy_threshold = 3
    port                = 80
    matcher             = "200"
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}