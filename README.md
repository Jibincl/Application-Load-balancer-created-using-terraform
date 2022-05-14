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
