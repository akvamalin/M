data "aws_ecr_image" "sample_service_image" {
  repository_name = var.ecr_repository_name
  image_tag       = "latest"
}

resource "aws_cloudwatch_log_group" "cw_log_group" {
  name = var.service_name
}

data "template_file" "container_definition" {
  template = file("${path.module}/container-definition.json")
  vars = {
    service_name           = var.service_name
    service_port           = var.service_port
    aws_logs_group         = aws_cloudwatch_log_group.cw_log_group.name
    aws_logs_region        = "eu-central-1"
    aws_logs_stream_prefix = var.service_name
    container_image        = var.image_url
  }
}

resource "aws_iam_role" "ecs_service_task_execution_role" {
  name = format("%s-ecs-service-role", var.service_name)

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = format("%s-cloudwatch", var.service_name)
  role = aws_iam_role.ecs_service_task_execution_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
                
            ],
            "Resource": "*"
        }
    ]
}
EOF
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

    routing_policy = "MULTIVALUE"
  }
}

resource "aws_ecs_service" "sample_service" {
  name            = var.service_name
  cluster         = var.ecs_cluster
  desired_count   = 2
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