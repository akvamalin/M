output "vpc_id" {
  value = module.vpc.vpc_id
}

output "cluster_namespace" {
  value = module.ecs_cluster.ecs_cluster_namespace
}