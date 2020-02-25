#!/bin/bash
terraform init
terraform apply -auto-approve

$(aws ecr get-login --no-include-email --region eu-central-1)
docker tag sample-app:0.0.1 870343420982.dkr.ecr.eu-central-1.amazonaws.com/ymcne2019/sample-service:latest
docker push 870343420982.dkr.ecr.eu-central-1.amazonaws.com/ymcne2019/sample-service:latest

docker tag prometheus-custom:0.0.1 870343420982.dkr.ecr.eu-central-1.amazonaws.com/ymcne2019/prometheus:latest
docker push 870343420982.dkr.ecr.eu-central-1.amazonaws.com/ymcne2019/prometheus:latest

