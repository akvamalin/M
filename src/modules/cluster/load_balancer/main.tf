resource "aws_lb" "alb" {
  name               = var.name
  load_balancer_type = "application"
  internal           = false
  subnets            = var.subnets
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No target group registered"
      status_code  = "200"
    }
  }
}