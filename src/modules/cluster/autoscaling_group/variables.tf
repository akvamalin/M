variable "cluster_namespace" {
  type        = string
  description = "ECS cluster namespace to register EC2 instance"
}


variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for cluster"
}

variable "subnets" {
  type        = list(string)
  description = "IDs of the subnets to launch the resources in"
}

variable "public_subnet" {
  type        = string
  description = "Public subnet ID to place a bastion EC2 instance in"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the security groups belong to"
}

variable "lb_security_group_id" {
  type        = string
  description = "Security Group of a load balancer to get the ingress traffic"
}