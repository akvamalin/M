output "listener_arn" {
  value = aws_lb_listener.listener.arn
}

output "alb_sg_id" {
  value = aws_security_group.lb_sg.id
}