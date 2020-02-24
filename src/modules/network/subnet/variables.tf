variable "vpc_id" {
  type        = string
  description = "ID of the VPC where the subnetworks are created"
}

variable "igw_id" {
  type        = "string"
  description = "Internet Gateway ID attached to the VPC"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR range for the vpc subnet"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR range for the vpc subnet"
}

variable "availability_zone" {
  type        = string
  description = "Availability zone where the subnet is deployed"
}