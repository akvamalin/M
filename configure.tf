provider "aws" {
    region = "eu-central-1"
}

resource "aws_s3_bucket"  "tf-state-bucket" {
    bucket = "ym-lmu-cne-2019-tf-state"
    acl = "private"

    tags = {
        Context = "CNE20192020"
    }
}

resource "aws_ecr_repository" "ecr" {
  name = "ymcne2019"
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
    name = format("www.%s", aws_route53_zone.primary.name)
    type = "CNAME"
    ttl = 300
    records = [aws_route53_zone.primary.name]
}

output "ecr_repository" {
    value = aws_ecr_repository.ecr.repository_url
}

output "dns_servers" {
    value = aws_route53_zone.primary.name_servers
}