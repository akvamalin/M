data "template_file" "container_definition" {
  template = file("${path.module}/container-definition.json")
  vars = {
    service_name           = var.service_name
    service_port           = var.service_port
    container_image        = var.image_url
  }
}

resource "aws_lb_target_group" "target_group" {
  name     = format("%s-lb-target-group", var.service_name)
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener_rule" "sample_service" {
  listener_arn = var.alb_listener_arn

  condition {
    host_header {
      values = [format("%s.%s", var.service_name, var.dns_name)]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_route53_record" "alb_record" {
  zone_id = var.zone_id
  name    = format("%s.%s", var.service_name, var.dns_name)
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_ecs_task_definition" "sample_service_task" {
  family                = var.service_name
  container_definitions = data.template_file.container_definition.rendered
  task_role_arn         = aws_iam_role.ecs_service_task_execution_role.arn
}

resource "aws_service_discovery_private_dns_namespace" "sd_dns_namespace" {
  name = format("%s.%s", var.service_name, "noname.local")
  vpc = var.vpc_id
}

resource "aws_service_discovery_service" "sds" {
  name = format("%s-service-discovery-service", var.service_name)

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.sd_dns_namespace.id

    dns_records {
      ttl = 10
      type = "SRV"
    }

    # use multivalue answer routing when you need to return multiple values 
    # for a DNS query and route traffic to multiple IP addresses.
    routing_policy = "MULTIVALUE"
  }
}

resource "aws_ecs_service" "sample_service" {
  name            = var.service_name
  cluster         = var.ecs_cluster
  desired_count   = 1
  task_definition = format("%s:%s", aws_ecs_task_definition.sample_service_task.family, aws_ecs_task_definition.sample_service_task.revision)

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = var.service_name
    container_port   = var.service_port
  }

  service_registries {
    registry_arn = aws_service_discovery_service.sds.arn
    container_port = var.service_port
    container_name = var.service_name
  }
}