#!/bin/bash
terraform init
terraform apply -auto-approve
docker push 870343420982.dkr.ecr.eu-central-1.amazonaws.com/ymcne2019:latest