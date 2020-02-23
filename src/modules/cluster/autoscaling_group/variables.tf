variable "cluster_namespace" {
    type = "string"
    description = "ECS cluster namespace to register EC2 instance"
}


variable "availability_zones" {
    type = list(string)
    description = "Availability zones for cluster"
}

variable "vpc_zone_id" {
    type = list(string)
    description = "IDs of the subnets to launch the resources in"
}