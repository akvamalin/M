## ECS optimized AMI
## https://eu-central-1.console.aws.amazon.com/systems-manager/parameters/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id/description?region=eu-central-1#
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "image-id"
    values = ["ami-0bfdae54e0eda93f2"]
  }
}

resource "aws_iam_role" "ec2_cluster_role" {
  name = "ec2_cluster_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_cluster_instance_policy" {
  name = "ec2_cluster_instance_policy"
  role = aws_iam_role.ec2_cluster_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "ec2:DescribeTags",
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:UpdateContainerInstancesState",
                "ecs:Submit*",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:DescribeImages",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_cluster_instance_profile" {
  name = "ec2_cluster_instance_profile"
  role = aws_iam_role.ec2_cluster_role.name
}

resource "aws_key_pair" "cluster_instances_pk" {
  key_name   = "ec2_cluster_instances_pk"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD5jqQ6nq4AV3k1ZvkWrIBKjegAj97HgZrUpWsb0C1YiBCySvPLjibpLtcuij148bGCvrmUWo9olpl0tKeFV1gXhJg76pV9JV+84vboCEOM4zY04la3x6ZQkJaet7XAgjapW3S2vtyY1g7JHVZhx70iUU9T5u8INNE8WjLDu/AT8FxkmyuFjbRw13gXXdu/mCi0ksvwq1bbd1v3ZdfuC/TgTdXD2FMx6GCkG5yAqyx3WwLKoYuLyptmj2aMPOFTTMtxwzb72p7r2w04N0X02HkKyWlFqLNoMMmnrECCEkB59Ja/YWhuzBsF2i5rO504iIncS+P+M6vx200Yo+2YE+3zKcktCArXn5fSq+8RZHk976UwuYX1jKvqssI3izHJvF97DYTHNj76ScTDjFi/qo6y5/io5AWj03D1yxsfdoEMnYMN2PUXqmasFfqU/oWav9N2TRkBIkRjxMAfgLFm8UVUFQHrHTfQymOqFBi5J7HehO65+0mjlB90hnBN+Cy0xWQLdERPG1n/0IG+zn1jQlR64I049uFnkS0onFjTDTRYrM1hTlSJyczpemLThE6YEcMmJgq69i1zk9c3CgayDUvtJ1Cq1wgZbvd29KME5jAyk25EpVr9rh7/5spNCaoVCjmZtlihl33RnA5Bx3mCQc6lz4AudTyESTf/HiKBJ6Da6w=="
}

## Used to ssh into private ec2 instances for checking the config
resource "aws_instance" "bastion_instance" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.amazon_linux.id
  key_name      = aws_key_pair.cluster_instances_pk.key_name

  tags = {
    Name = "Bastion"
  }

  subnet_id = var.public_subnet
}

resource "aws_security_group" "ec2_security_group" {
  name   = "ec2-security-group"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.lb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "sg_rule" {
  type                     = "ingress"
  to_port                  = 65535
  from_port                = 0
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_security_group.id
  security_group_id        = aws_security_group.ec2_security_group.id
}

resource "aws_launch_template" "autoscaling_launch_template" {
  name          = "autoscaling_template"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  iam_instance_profile {
    name = "ec2_cluster_instance_profile"
  }
  user_data = filebase64("${path.module}/userdata.sh")
  key_name  = aws_key_pair.cluster_instances_pk.key_name

  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
}

resource "aws_autoscaling_group" "main" {
  min_size           = 1
  max_size           = 3
  desired_capacity   = 3
  availability_zones = var.availability_zones

  launch_template {
    id      = aws_launch_template.autoscaling_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = var.subnets
}