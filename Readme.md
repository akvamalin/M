# Infrastructure for highly-available monitored microservices

## Abstract

The value of this project is to implement a production-ready system in the cloud for keeping track of highly-available data-processing microservices, monitoring how they perform and detecting faults quickly.


### Background 
A microservice is deployed to a production ready system. From a developer point of view, it is important to detect any faults and monitor the resource usage in order to be compliant with SLAs and provide a certain percentage of service availability. As soon as either a fault in the service or resource usage spikes occur, a developer must me notified and must be able to see and understand the cause of the problem.

An imaginary real-life sample is given to provide better understanding of the system.

Any outage, errors or malicious behavior of the microservice must be automatically detected and reported. This helps the developers and mainteiners of the service to react accordingly. For instance, the `pizza-service` is expected to serve around 10 000 orders per hour. Number of created orders exceeding 20 000 is considered to be strange behaviour and must be automatically detected and reported. Another example is the number of orders that failed in creation due to some factor. If the number of failed orders reaches e.g. 500, this situation should be detected and reported. 

Therefore, a system is needed that enables the detection of any anomalies that are reported automatically.



## 1. Project objective 

The objective of this project is to learn how to configure a cloud infrastrucuter and setup monitoring along with alerting according to the cloud best practices. This involves investigating and applying the concepts of *containerized applications, web communication protocols, cloud security, logging and monitoring, alerting, service discovery, autoscaling, roles and permissions in cloud as well as infrastructure as code*. Those concepts are applied in the AWS Cloud Provider. 

The general approach of this project is following:
1. Describe the architecture of the whole system.
2. Analyze the required components (say, building blocks) needed to construct the system.
3. Configure the Cloud infrastructure from scratch.
4. Plan, prepare and deploy the components enabling the monitoring and alerting
5. Prepare a demonstration with a use-case. 

**Keywords**: AWS ECS, ECR, Route53, IAM, KMS, ALB, Security Groups, VPC, Prometheus, Grafana, Terraform, Python, Flask.


## 2. Implementation

A starting point of this project is to setup a virtual private cloud. A VPC, in terms of Amazon Web Services, is a virtual data center given into one's control. It's a backbone for the whole system.

## 2.1. Build a VPC
To setup a VPC, the following components need to be deployed and configured:
1. VPC.
2. Subnets.
3. Routing.
4. Availability Zones.
5. Computing resources.

### 2.1.1. VPC
In order to deploy a VPC, a classless inter-domain routing (following as `CIDR`) range needs to be specified. 

#### CIDR range
The selected CIDR range is: `10.0.0.0/16`. The choice of the CIDR range is important and must be investaged in more details as it defines the number of virtual machines as well as subnets that can be created within the VPC.

#### Internet Gateway
In order to enable the Internet communication from and to the created VPC, an Internet Gateway must be created. According to the AWS, `An internet gateway is a horizontally scaled, redundant, and highly available VPC component that allows communication between instances in your VPC and the internet`. [AWS Source](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html).

#### Access Control Lists
ACLs are firewalls that are attached to the VPC or subnets. The ACLs are used to make coarse-grained traffic filtering instead of fine-grained which is the job of security groups. E.g., ACLs are used to DENY/ALLOW traffic from one specific IP range. 

For the sake of this projects, ACLs are defaul and allow all traffic, even though they should be explicitly specified. 

Note! When taking a look at terraform code defining ACLs, there are rule priorities. The rule is evaluated in exclusive way based on priority. If ALLOW is evaluated, then no further DENY is taken into account.

#### Terraform
The mentioned above components can be deployed and configured via the following terraform code.

**/src/modules/network/vpc/main.tf** 
```hcl
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr_range
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.main_vpc.id

  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    action     = "allow"
    rule_no    = 100
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    action     = "allow"
    rule_no    = 100
    cidr_block = "0.0.0.0/0"
  }

  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    action     = "deny"
    rule_no    = 1000
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    action     = "deny"
    rule_no    = 1000
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "main_acl"
  }
}
```

### 2.1.2. Subnets
As soon as the backbone has been set up, the next step is to define and configure subnets. 

The subnets are subdivisions of the initial CIDR range.

One of the best practices is to divide a VPC into a **public** and **private** subnet.
The difference between the public and private subnets is that each entity (put simply, virtual machine) attached to the public subnet, gets automatically a public IP address assigned along with a private one and can be reached from the Internet. The virtual machines, attached to the private subnet are assigned only private IP addresses. 


Note, the private IP addresses are taken from the specified CIDR range.


Why is the public/private split needed? The systems outside are not allowed to access all the services by default. This can be illustrated on a simple use-case of a traditional web application, where the web server faces the internet traffic and routes it to the web application that is connected to the database. In this setup, the web server is allocated into a public subnet, the web application and database in a  private one. 


Therefore, for the sake of this project, the two CIDRs for subnets are selected:
1. 10.0.1.0/24 - private subnet.
2. 10.0.11.0/24 - public subnet.


### 2.1.3. Routing
Before placing any computing resources into the subnets, the routing within the VPC must be configured. 

**Public subnet**
All the virtual machines/components put into the public subnet must be able to communicate with the Internet as well as with the entities within the VPC itself. Therefore two entries to the routing table for public subnet are added:
* one allowing outbound traffic to the Internet Gateway.
* one saying connections within the VPC are routed to the VPC network.

**Private subnet** 
The case for a private subnet is pretty similar, however instead of routing any outbound traffic to the Internet Gateway,  the traffic is routed to the NAT Gateway that is attached to the public subnet and therefore has a public IP address.

**NAT Gateway**
NAT Gateway, routing the traffic from private subnet to the  public subnet,  is attached to the public subnet, has its own public IP address and has a routing table attached to it. The routing table routes any outbound traffic to the Internet Gateway.

The NAT gateway is one-way wall. It allows responses to the requests that come from inside, others are rejected.  In routing, the instances launched in a private subnet, are going to the NAT gateway which in its turn goes to Internet gateway. That is how outbound internet access is achieved. The Internet can only respond to the requests. For sending the requests, it requires Inbound internet access. 

#### Terraform code
**/src/modules/network/subnet/main.tf** 
```hcl
resource "aws_subnet" "public" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = format("public %s", var.availability_zone)
  }
}

resource "aws_subnet" "private" {
  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = format("private %s", var.availability_zone)
  }
}

## NAT Gateway configuration
resource "aws_eip" "nat_gw_ip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw_ip.id
  subnet_id     = aws_subnet.public.id
}

resource "aws_route_table" "nat_gw_routing_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    Name = format("NAT %s", var.availability_zone)
  }
}

resource "aws_route_table_association" "nat_gw_routes" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_routing_table.id
}

## Private subnet configuration
resource "aws_route_table" "private_routing_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = format("private subnet %s", var.availability_zone)
  }
}

resource "aws_route_table_association" "private_subnet_routes" {
  route_table_id = aws_route_table.private_routing_table.id
  subnet_id      = aws_subnet.private.id
}

## Public subnet configuration  
resource "aws_route_table" "public_routing_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    Name = format("public subnet %s", var.availability_zone)
  }
}

resource "aws_route_table_association" "public_subnet_routes" {
  route_table_id = aws_route_table.public_routing_table.id
  subnet_id      = aws_subnet.public.id
}
```

### 2.1.4. Availability zones
In the posted terraform code above there are mentions of availability zones.

To put it simple, availability zones - separate risk domains, each of them are in one or more data centers, on different power grids and completely independent. If something affects one availability zone, it would not affect all of them.

Therefore, the 2 more subnets as well as a NAT gateway are deployed, however to another availability zone:
* 10.0.2.0 - private subnet
* 10.0.22.0 - public subnet

This would result in following terraform code:
**/src/main.tf**
```hcl
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
```

More on regions and availability zones [here](https://blog.rackspace.com/aws-101-regions-availability-zones).


#### 2.1.5. Computing resources
As soon as the network infrastructure is ready, the computing resources can be deployed to the VPC. 

The virtual machines, EC2 instances in terms of AWS, run container workloads.  

Depending on the subnet, to which an EC2 instance is attached, it will get either private IP address or both private and public. 

For the sake of project, the t2.micro type of a virtual machine has been chosen. More information on the machine characteristics is on [AWS](https://aws.amazon.com/ec2/instance-types/?nc1=h_ls)

**Key question** is how to provision the computing capacity and make it constantly available?
One approach would be to manually launch desired number of instances and manually check that the required computing capacity is availabe. The second approach would be to automate this.

**Auto-scaling groups** is one of the AWS services that, when configured correctly, takes over the responsibility for sustaining the desired computing resources and performing health-checks.

The following information is required to launch an instance.
1. Which type of machine image to use? (Linux, Suse, Windows)
2. On which virtual machine to launch, in other words, what are the virtual machine characteristics?
3. What is the minimum VM number, maximum, as well as desired.

Providing this information to the auto-scaling group would ensure that the desired computing capacity is available.

Along with that information, several additional options were supplied to the autoscaling group:
1. The script to perform on the startup of the virtual machine (more details on this in further sections) (Launch template, userdata script).
2. Behind which firewalls to put the virtual machine (Security Groups)
3. What are other services the virtual machine is allowed to call within the VPC (IAM policies and roles).

Another crucial for `high-availability`concept is the availability zones. Those are also given to the autoscaling group so that the virtual machines that are spinned up are distributed accross availability zones depending on specified strategy. E.g. if the desired number of virtual machines is 2, 1 will be located in a private subnet 10.0.11.0/24 (availability zone a) and another one in a private subnet 10.0.22.0/24 (availability zone b) that have been created previously.


In order to check that the subnets (private/public) and instances within those subnets behave as expected (connectivity, conneciton to the Internet), a so called "Bastion" instance has been added -> ssh to public then to private instance and check via ping.

#### Terraform
**/src/modules/cluster/autoscaling_group/main.tf**
```hcl
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

... 

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
```

## 2.2. Container cluster
Now the basic infrastructure is ready: the network is configured, routing and connectivity is setup, computing resources are provisioned. In order to utilize virtualization and provisioned resources in an efficient way, the services will be deployed not on the raw machines, however using container cluster (of course there  are many other pros of using containers for HTC too).


### 2.2.1. Tasks

The work distribution is therefore delegated to an agent that will schedule the tasks onto the virtual machines.

To start with,  the basic terminology is clarified.

A **task** is a running containerized application that is deployed by a cluster agent onto the virtual machine.

The task is created by the cluster agent according to the task definition which specifies the required resources as well as the container image.

The cluster agent consumes the service definition, which is the the task definition along with the number of tasks that need to be provisioned.

After the service definition is deployed and the tasks are created and distributed over the instances, the application is running and ready to be accessed.

#### Terraform
These code snippets show one of the service definitions.

**container-definition.json**
```json
  {
        "name": "${service_name}",
        "image": "${container_image}",
        "cpu": 128,
        "memory": 128,
        "essential": true,
        "portMappings": [
            {
                "containerPort": ${service_port}
            }
        ],
```

```hcl
resource "aws_cloudwatch_log_group" "cw_log_group" {
  name = var.service_name
}

data "template_file" "container_definition" {
  template = file("${path.module}/container-definition.json")
  vars = {
    service_name           = var.service_name
    service_port           = var.service_port
    aws_logs_group         = aws_cloudwatch_log_group.cw_log_group.name
    aws_logs_region        = "eu-central-1"
    aws_logs_stream_prefix = var.service_name
    container_image        = var.image_url
  }
}

resource "aws_iam_role" "ecs_service_task_execution_role" {
  name = format("%s-ecs-service-role", var.service_name)

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = format("%s-cloudwatch", var.service_name)
  role = aws_iam_role.ecs_service_task_execution_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
                
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_lb_target_group" "target_group" {
  name     = format("%s-lb-target-group", var.service_name)
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener_rule" "sample_service" {
  listener_arn = var.alb_listener_arn

  condition {
    host_header {
      values = [format("%s.%s", var.service_name, var.dns_name)]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_route53_record" "alb_record" {
  zone_id = var.zone_id
  name    = format("%s.%s", var.service_name, var.dns_name)
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_ecs_task_definition" "sample_service_task" {
  family                = var.service_name
  container_definitions = data.template_file.container_definition.rendered
  task_role_arn         = aws_iam_role.ecs_service_task_execution_role.arn
}

resource "aws_service_discovery_private_dns_namespace" "sd_dns_namespace" {
  name = format("%s.%s", var.service_name, "noname.local")
  vpc  = var.vpc_id
}

resource "aws_service_discovery_service" "sds" {
  name = format("%s-service-discovery-service", var.service_name)

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.sd_dns_namespace.id

    dns_records {
      ttl  = 10
      type = "SRV"
    }

    # use multivalue answer routing when you need to return multiple values 
    # for a DNS query and route traffic to multiple IP addresses.
    routing_policy = "MULTIVALUE"
  }
}

resource "aws_ecs_service" "sample_service" {
  name            = var.service_name
  cluster         = var.ecs_cluster
  desired_count   = 2
  task_definition = format("%s:%s", aws_ecs_task_definition.sample_service_task.family, aws_ecs_task_definition.sample_service_task.revision)

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = var.service_name
    container_port   = var.service_port
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.sds.arn
    container_port = var.service_port
    container_name = var.service_name
  }
}
```

### 2.2.2. Making the service accessible
Even though the services are up and running, they are still not accessible from the outside. In first step, I  would ask myself: 
* How could they be accessed?
* What is the IP and port as I don't deploy them myself but delegate it to cluster agent.
* They are deployed on the instances in a private subnet, how could they be accessed then?
* How to dynamically discover the IP address and port as the containers are stopped and spinned up automatically?

The load balancer comes to the rescue.
There are several types of load balancers, but the used one for this project is the Application Load Balancer provided by the AWS. 

According to the definition of an ALP of the AWS `A load balancer serves as the single point of contact for clients. The load balancer distributes incoming application traffic across multiple targets, such as EC2 instances, in multiple Availability Zones. This increases the availability of your application`. The ALB, in particular, only serves the HTTP/HTTPS traffic.

To put it simple, the ALB is attached to public subnets, processes the incomming HTTP/HTTPS requests and depending on the defined rules routes the requests and responses. Two key questions: What are those rules and where does it route the traffic.

The rules are conditions that, when fulfilled, trigger an action. E.g. if the hostname is x.y -> route traffic to that location, if the hostname is t.y -> to another location.

In order to know where to route the traffic if a condition is met, the ALB has so called "target groups". The targets are, in our particular case, the containers. 

The target groups can be imagined as table records containing the entries in form of service -> location. These entries are added/removed by the cluster agent as it spins up/terminates the containers.

More nice explanation on ALB and target groups on [AWS page](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html).


### 2.3. Deploying services
Now that the infrastructure is ready, all of the planned services can be deployed:
1. `sample-service` - simple service, exposes metrics.
2. `prometheus` - collects metrics, aggregates, reduces, etc.
3. `alert-manager` - sends alerts on predefined conditions.
4. `grafana` - visualizes metrics.

All of the services, except `sample-service` are official container images pulled from docker registry and extended with custom setup.

The exteded images are then uploaded to the AWS Container Registry, (look `/persistent/persistent.tf`) and used in the task definitions.


#### 2.3.1 DNS with Route53
In order to make the services easily accessible, the domain names have been setup. Depending on the subdomain, the application load balancer routes the traffic to the corresponding target group.
1. https://sample-service.noname.engineer
1. https://grafana.noname.engineer
1. https://prometheus.noname.engineer
1. https://alertmanager.noname.engineer


#### 2.3.2 Service Discovery
The prometheus collects the metrics of the services. In this particular project, the prometheus scraps the `/metrics` endpoint of the sample-service.

The location of the sample-service instances is discovered using the Service Discovery mechanism. This mechanism is implemented by the ECS service discovery directory and private hosted zone with SRV records.

Better to explain that on diagrams which are currently missing.


### 3. Demo
**sample-service metrics**
![](./docs/metrics.png)

**prometheus**
![](./docs/targets.png)

![](./docs/prometheus.png)

**grafana**
![](./docs/grafana.png)

Lets cause some traffic.
If there are too many requests per minute, the alert to the slack channel should be sent.

```bash
for ((i=1;i<100;i++)); do curl "https://sample-service.noname.engineer/" ; done
```

**grafana**
![](./docs/grafana-load.png)

**alertmanager**
![](./docs/alertmanager.png)

**slack**
![](./docs/slack.png)

### 4. Room for improvement
1. Put the prometheus, prometheus-alerter behind the private load balancer (ommited in order to show something in the presentation, or would need to setup VPN server)
2. Terraform apply is very inconsistent now, would need to call it more than once because of some resource dependencies.


### 5. How to run
1. Create an AWS Free tier account.
2. Deploy persistent resources (hosted zone, ecr repos) (needs a certificate, domain name etc)
3. Goto *src*
4. run `tf apply` and approve deployment

### TODO
* Diagrams are incomming


# And btw
This is my first blood with AWS infrastructure in terms of EC2, clusters, security,  service discovery, VPC etc, so this was supposed to give me understanding of the  concepts.

Thanks a lot to my lovely colleagues G.G. and M.S. for supporting me and patiently answering all my stupid basic questions. Your way of explaining things with pencil and paper is excellent, thank you so much.
