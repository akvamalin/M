 provider "aws" {
    region = "eu-central-1"
}

terraform {
    backend "s3" {
        bucket = "ym-lmu-cne-2019-tf-state"
        key = "tfstate"
        region = "eu-central-1"
    }
}

module "vpc" {
    source = "./modules/network/vpc"
    vpc_cidr_range = "10.0.0.0/16"
}

module "availability_zone_a" {
    source = "./modules/network/subnet"
    vpc_id = module.vpc.vpc_id
    igw_id = module.vpc.igw_id
    private_subnet_cidr = "10.0.1.0/24"
    public_subnet_cidr = "10.0.11.0/24"
    availability_zone = "eu-central-1a"
}

module "availability_zone_b" {
    source = "./modules/network/subnet"
    vpc_id = module.vpc.vpc_id
    igw_id = module.vpc.igw_id
    private_subnet_cidr = "10.0.2.0/24"
    public_subnet_cidr = "10.0.22.0/24"
    availability_zone = "eu-central-1b"
}

module "ecs_cluster" {
    source = "./modules/cluster/ecs"
    ecs_cluster_namespace = "ymcne2019"
}

module "autoscaling_group" {
    source = "./modules/cluster/autoscaling_group"
    cluster_namespace = module.ecs_cluster.ecs_cluster_namespace
    availability_zones = ["eu-central-1a", "eu-central-1b"]
    vpc_zone_id = [module.availability_zone_a.private_subnet_id, module.availability_zone_b.private_subnet_id]
}