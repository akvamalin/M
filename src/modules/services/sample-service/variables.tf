variable "alb_listener_arn" {
  type        = string
  description = "The ARN of the listener to which to attach the rule"
}

variable "service_name" {
  type        = string
  description = "Service name"
}

variable "service_port" {
  type = number
}

variable "ecr_repository_name" {
  type        = string
  description = "ECR repository name where the image lies"
}

variable "ecs_cluster" {
  type        = string
  description = "Cluster where to put the service"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where to put the target group"
}

variable "image_url" {
  type = string
  description = "URL of the docker image"
}