variable "subnets" {
  type        = list(string)
  description = "List of subnets to be attached to the ALB"
}

variable "vpc_id" {
  type        = string
  description = "The identifier of the VPC in which to create the target group."
}

variable "name" {
  type        = string
  description = "ALB name"
}

variable "zone_id" {
  type        = string
  description = "Route53 zone ID"
}