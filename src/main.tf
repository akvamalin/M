provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "ym-lmu-cne-2019-tf-state"
    key    = "tfstate"
    region = "eu-central-1"
  }
}

data "aws_route53_zone" "primary" {
  name         = "noname.engineer."
  private_zone = false
}

module "vpc" {
  source         = "./modules/network/vpc"
  vpc_cidr_range = "10.0.0.0/16"
}

module "availability_zone_a" {
  source              = "./modules/network/subnet"
  vpc_id              = module.vpc.vpc_id
  igw_id              = module.vpc.igw_id
  private_subnet_cidr = "10.0.1.0/24"
  public_subnet_cidr  = "10.0.11.0/24"
  availability_zone   = "eu-central-1a"
}

module "availability_zone_b" {
  source              = "./modules/network/subnet"
  vpc_id              = module.vpc.vpc_id
  igw_id              = module.vpc.igw_id
  private_subnet_cidr = "10.0.2.0/24"
  public_subnet_cidr  = "10.0.22.0/24"
  availability_zone   = "eu-central-1b"
}

module "public_load_balancer" {
  name    = "public-load-balancer"
  source  = "./modules/cluster/load_balancer"
  vpc_id  = module.vpc.vpc_id
  subnets = [module.availability_zone_a.public_subnet_id, module.availability_zone_b.public_subnet_id]
  zone_id = data.aws_route53_zone.primary.zone_id
}


module "autoscaling_group" {
  source               = "./modules/cluster/autoscaling_group"
  cluster_namespace    = module.ecs_cluster.ecs_cluster_namespace
  availability_zones   = ["eu-central-1a", "eu-central-1b"]
  subnets              = [module.availability_zone_a.private_subnet_id, module.availability_zone_b.private_subnet_id]
  public_subnet        = module.availability_zone_a.public_subnet_id
  vpc_id               = module.vpc.vpc_id
  lb_security_group_id = module.public_load_balancer.alb_sg_id
}

module "ecs_cluster" {
  source                = "./modules/cluster/ecs"
  ecs_cluster_namespace = "ymcne2019"
}


module "sample_service" {
  source              = "./modules/services/sample-service"
  vpc_id              = module.vpc.vpc_id
  ecr_repository_name = "ymcne2019/sample-service"
  ecs_cluster         = module.ecs_cluster.ecs_cluster_namespace
  alb_listener_arn    = module.public_load_balancer.listener_arn
  service_name        = "sample-service"
  service_port        = 5000
  image_url           = "870343420982.dkr.ecr.eu-central-1.amazonaws.com/ymcne2019/sample-service:latest"
  alb_dns_name        = module.public_load_balancer.alb_dns_name
  alb_zone_id         = module.public_load_balancer.alb_zone_id
  zone_id             = data.aws_route53_zone.primary.zone_id
  dns_name            = "noname.engineer"
}

module "prometheus" {
  source              = "./modules/services/prometheus"
  vpc_id              = module.vpc.vpc_id
  ecr_repository_name = "ymcne2019/prometheus"
  ecs_cluster         = module.ecs_cluster.ecs_cluster_namespace
  alb_listener_arn    = module.public_load_balancer.listener_arn
  service_name        = "prometheus"
  service_port        = 9090
  image_url           = "870343420982.dkr.ecr.eu-central-1.amazonaws.com/ymcne2019/prometheus:latest"
  alb_dns_name        = module.public_load_balancer.alb_dns_name
  alb_zone_id         = module.public_load_balancer.alb_zone_id
  zone_id             = data.aws_route53_zone.primary.zone_id
  dns_name            = "noname.engineer"
}
