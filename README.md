# AWSTerraformUtils

Terraform scripts to build ressources (VPC, Cluster...) on AWS

There are 2 modules to help build resources in EFS and ECS service. Currently ECS module builds only with _Fargate_ mode. EFS resources are created if persistant storage is required.

The `main.tf` script is intended to create a VPC with at least 2 subnets publics. If variable `private_subnets` is not declared, only public subnets are created.
By default no NAT gateway is created, leaving private_subnets unreachable from outside.
A security group for inbound http connections is also created.
One ECS cluster is created and one service also. All tasks will be running in this service.

To call this script, simply run `tf apply -var-file input-app.tfvars.json -auto-approve` where `input-app.tfvars.json` is the file with variables used to created the resources, among them the task definitions. See [here](https://docs.aws.amazon.com/AmazonECS/latest/userguide/task_definition_parameters.html) for the list.

## tfvars.json file

In this file enter values of the variables required to create the AWS ressources : subnets, ingress rules, NAT, public IPs...

The task definition parameters used the scheme from Amazon, only one parameter has been added : in `mountPoints`, `persistant_storage` is a boolean that will create accordingly an EFS volume (if true).

## Useful commands

command|case
-|-
`tf destroy -var-file django-test-app.tfvars.json -auto-approve`
`ecs-cli ps -desired-status RUNNING`

