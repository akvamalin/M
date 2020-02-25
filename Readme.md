# WIP: Setting up telemetry data and monitoring service via Grafana & Prometheus for a microservice

## Abstract

The value of this project is to implement a production-ready system into the cloud for keeping track of highly-available data-processing microservices, monitoring how they perform and detecting faults quickly.

To be more specific, a following use-case is given. 

A microservice is deployed to a production ready system. From a developer point of view, it is important to detect any faults and monitor the resource usage in order to be compliant with SLAs and provide a certain percentage of service availability. As soon as either a fault in the service or resource usage spikes occur, a developer must me notified and must be able to see and understand the cause of the problem.

An imaginary real-life sample is given to provide better understanding of the system.

Any outage, errors or malicious behavior of the microservice must be automatically detected and reported. This helps the developers and mainteiners of the service to react accordingly. For instance, the `pizza-service` is expected to serve around 10 000 orders per hour. Number of created orders exceeding 20 000 is considered to be strange behaviour and must be automatically detected and reported. Another example is the number of orders that failed in creation due to some factor. If the number of failed orders reaches e.g. 500, this situation should be detected and reported. 

Therefore, a system is needed that enables the detection of any anomalies that are reported automatically.


## 1. Project objective 

The objective of this project is to learn how to deploy and configure a complex monitoring and alerting system according to the cloud best practices. This involves investigating in details and applying the concepts of *containerized applications, web communication protocols, cloud security, logging and monitoring, alerting, service discovery, autoscaling, roles and permissions in cloud as well as infrastructure as code*. Those concepts are applied in the AWS Cloud Provider. 

The general approach of this project is following:
1. Describe the architecture of the whole system.
2. Analyze the required components (say, building blocks) needed to construct the system.
3. Prepare the starting point for implementing the monitoring and alerting system. That means setting up basic cloud infrastrucutre, a dummy microservice, deploying it to the cloud as if production ready (auto-scaling, load-balaning, security are investigated and added). This process is described in details as the project is done from  scratch and the infrastructure does not exist at all.
4. Plan, prepare and deploy the components enabling the monitoring and alerting. These steps are described in details and with argumentations. 
5. Prepare a demonstration with a use-case. 

**Keywords**: AWS ECS, ECR, Route53, IAM, KMS, ALB, Security Groups, VPC, Prometheus, Grafana, Terraform, Python, Flask.

## 2. Implementation

## 2.1. Build a VPC
An AWS Virtual Private Cloud is a virtual data center where things are deployed. 
To setup a VPC, the following things need to be configured:
1. IP addressing
2. Subnets
3. Routing in a VPC
4. Security. 

### 2.1.1. IP addressing
Select CIDR range.

Availability zones - separate risk domains, each of them are in one or more data centers, on different power grids and completely independent. If something affects one availability zone, it would not affect all of them.

There is the place where the subnets come into place. The subnets are subdivisions of the initial CIDR range. Each of the availability zones is a subnet. 

Routing in a VPC.


3 things are needed in order to communicate with the Internet.
1. Some form of connection.
2. Route.
3. Public address.


1. Public subnet means that each instance launched in public  subnet gets a public IP address along with a private IP address.
2. Internet Gateway is added to the VPC so that the connection exists.
3. Add the  route -> the default  way of getting out of subnet is via IGW.

A private subnet -> stick with a private range, don't give me a public IP address. The use case for that is  that the systems from outside cannot access  my system by default. 

In  order to give the private subnet an access to the Internet, the NAT gateway is used. The NAT gateway is one-way wall. It allows responses to the requests that come from inside, others are rejected.  In routing, the instances launched in a private subnet, are going to the NAT gateway which in its turn goes to Internet gateway. That is how outbound internet access is achieved. The Internet can only respond to the requests. For sending the requests, it requires Inbound internet access. 

Security.

Security Goups - AWS distributed firewalls, operate on instance level.

Network access control list - operate at subnet level, coarse-grained desicions.

## TO  READ:
Regions and availability zones: https://blog.rackspace.com/aws-101-regions-availability-zones



### ECR Login:
```bash
$(aws ecr get-login --no-include-email --region eu-central-1)
$ docker tag sample-app:0.0.1 <account_number>.dkr.ecr.eu-central-1.amazonaws.com/ymcne2019:latest
$ docker push <account_number>.dkr.ecr.eu-central-1.amazonaws.com/ymcne2019:latest
```

https://aws.amazon.com/ec2/instance-types/?nc1=h_ls


## 3. Demo

Bastion -> ssh to public then to private instance and check the ping
## 4. Conclusion

## 5. Bibliography