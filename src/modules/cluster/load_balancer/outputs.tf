output "listener_arn" {
  value = aws_lb_listener.listener.arn
}

output "alb_sg_id" {
  value = aws_security_group.lb_sg.id
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

# The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record).
output "alb_zone_id" {
  value = aws_lb.alb.zone_id
}