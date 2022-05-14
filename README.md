# Application-Load-balancer-created-using-terraform

## Description

Creating an Application Load Balancer(ALB) using terraform, here we create VPC, security group, Target group for LB, ALB and its listner, also the Lauch configuration and auto scaling group as well.

## Prerequisites

Before we get started you are going to need so basics:

* [Basic knowledge of Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [Terraform installed](https://www.terraform.io/downloads)
* [Valid AWS IAM user credentials with required access](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)

## Installation

If you need to download terraform , then click here [Terraform](https://www.terraform.io/downloads)

Lets create a file for declaring the variables.This is used to declare the variables that pass values through the terrafrom.tfvars file.

### Create a varriable.tf file

~~~
variable "vpc_cidr" {
default = "172.17.0.0/16"
}

variable "project" {
default = "zomato"
}

variable "image" {
default = "ami-04893cdb768d0f9ee"
}

variable "key" {
default = "devops-new"
}

variable "instance_type" {
default = "t2.micro"
}

variable "count_asgone" {
default = "2"
}
~~~

### Create a provider.tf file

~~~
provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}
~~~

### Create a datasource.tf file

~~~
data "aws_route53_zone" "selected" {
  name         = "sanudas.online"
  private_zone = false
}

output "zone" {
value = data.aws_route53_zone.selected.id
}
~~~

### Create a userdata file

~~~
#!/bin/bash

yum install httpd php -y
cat <<EOF > /var/www/html/index.php
<?php
\$output = shell_exec('echo $HOSTNAME');
echo "<h1><center><pre>\$output</pre></center></h1>";
echo "<h1><center>Shopping-app-version2</center></h1>"
?>
EOF
service httpd restart
chkconfig httpd on
~~~

Go to the directory that you wish to save your tfstate files.Then Initialize the working directory containing Terraform configuration files using below command.

~~~
terraform init
~~~

Lets start with main.tf file, the details are below

~~~
module "vpc" {

  source   = "git@github.com:Jibincl/Terraform-for-AWS-VPC.git"
  vpc_cidr = var.vpc_cidr
  project  = var.project

}
~~~

To create security group

~~~
resource "aws_security_group" "freedom" {
  name        = "freedom"
  description = "allows 22,80,443 conntection"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    description      = ""
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  ingress {
    description      = ""
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  ingress {
    description      = ""
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

   tags = {
    Name = "${var.project}-freedom"
    project = var.project
  }
}
~~~

To create Target group

~~~
resource "aws_lb_target_group" "tgone" {
  name        = "targetgroup"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = 200
  }

  lifecycle {
    create_before_destroy = true
  }
}
~~~

To create ALB

~~~
resource "aws_lb" "albtg" {
  name               = "albfrontend"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.freedom.id ]
  subnets            = module.vpc.public_subnet

  enable_deletion_protection = false
  depends_on = [ aws_lb_target_group.tgone ]

  tags = {
    Name = var.project
  }
}
~~~

To create ALB listner with default action

~~~~
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.albtg.arn
  port              = "80"
  protocol          = "HTTP"

default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = " No such Site Found"
      status_code  = "200"
   }
}
}
~~~

To create forwarding rule

~~~
resource "aws_lb_listener_rule" "rule-one" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 5
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tgone.arn
  }
  condition {
    host_header {
      values = [ "${var.project}.sanudas.online" ]
     }
  }
}
~~~

to create Lauch Configuration

~~~
resource "aws_launch_configuration" "webserverlc" {
  name          =  "${var.project}-1"
  image_id      =  var.image
  instance_type =  var.instance_type
  key_name      = var.key
  security_groups = [ aws_security_group.freedom.id ]
  user_data  = file("user.sh")

  lifecycle {
    create_before_destroy = true
   }
}
~~~

To create ASG

~~~
resource "aws_autoscaling_group" "asg-one" {
  launch_configuration    = aws_launch_configuration.webserverlc.id
  health_check_type       = "EC2"
  min_size                = var.count_asgone
  max_size                = var.count_asgone
  desired_capacity        = var.count_asgone
  vpc_zone_identifier     = module.vpc.public_subnet
  target_group_arns       = [ aws_lb_target_group.tgone.arn ]
  tag {
    key = "Name"
    propagate_at_launch = true
    value = "Asg-one"
  }

  lifecycle {
    create_before_destroy = true
  }
}
~~~

To add record to Route53

~~~
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.id
  name    = "${var.project}.${data.aws_route53_zone.selected.name}"
  type    = "A"

  alias {
    name                   = aws_lb.albtg.dns_name
    zone_id                = aws_lb.albtg.zone_id
    evaluate_target_health = true
  }
}
~~~

Lets validate the terraform files using

~~~
terraform validate
~~~

Lets plan the architecture and verify once again

~~~
terraform plan
~~~

Lets apply the above architecture to the AWS.

~~~
terraform apply
~~~

### Conclusion 

This is a Application load balancer using terraform. Please contact me when you encounter any difficulty error while using this terrform code. Thank you and have a great day!
