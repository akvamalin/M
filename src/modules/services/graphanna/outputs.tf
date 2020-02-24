
resource "aws_ecs_task_definition" "sample_service" {
  family = "sample_service"

  container_definitions = <<DEFINITION
    


DEFINITION
}