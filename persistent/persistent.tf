provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "tf-state-bucket" {
  bucket = "ym-lmu-cne-2019-tf-state"
  acl    = "private"

  tags = {
    Context = "CNE20192020"
  }
}

resource "aws_ecr_repository" "sample_service" {
  name = "ymcne2019/sample-service"
  ## Tags of already pushed images cannot be overwritten, CI/CD  approach
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "prometheus" {
  name = "ymcne2019/prometheus"
  ## Tags of already pushed images cannot be overwritten, CI/CD  approach
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "grafana" {
  name = "ymcne2019/grafana"
  ## Tags of already pushed images cannot be overwritten, CI/CD  approach
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_route53_zone" "primary" {
  name = "noname.engineer"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = format("www.%s", aws_route53_zone.primary.name)
  type    = "CNAME"
  ttl     = 300
  records = [aws_route53_zone.primary.name]
}

output "sample_service_image_url" {
  value = aws_ecr_repository.sample_service.repository_url
}

output "prometheus_image_url" {
  value = aws_ecr_repository.prometheus.repository_url
}

output "grafana_image_url" {
  value = aws_ecr_repository.grafana.repository_url
}

output "dns_servers" {
  value = aws_route53_zone.primary.name_servers
}