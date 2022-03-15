terraform {
    required_providers {
        aws = {
            source    = "hashicorp/aws"
            version   = "~> 3.50"
        }
    }
    required_version  = "~> 1.0"
}

provider "aws" {
    region = var.region
}

locals {
  efs_volumes_path_to_create = matchkeys(flatten(var.containers_definition[*].mountPoints[*].containerPath),flatten(var.containers_definition[*].mountPoints[*].persistant_storage),[true])
}

# Create the VPC and subnets
module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    //name                        = "project-${var.tags.Name}"

    azs                         = ["${var.region}a","${var.region}b"]
    cidr                        = var.cidr_main_vpc
    public_subnets              = var.public_subnets
    private_subnets             = var.private_subnets != null ? var.private_subnets : null
    enable_nat_gateway          = var.private_subnets != null ? var.enable_nat : null
    single_nat_gateway          = true
    one_nat_gateway_per_az      = true
    
    enable_dns_hostnames        = true # to let ECS service access EFS via AP see https://aws.amazon.com/fr/premiumsupport/knowledge-center/ecs-pull-container-error/
    enable_dns_support          = true
    # manage_default_route_table  = true
    # default_route_table_routes  = var.routes

    tags = var.tags
    private_subnet_tags         = merge(var.tags,{Name="${var.tags.Name}_private"})
    public_subnet_tags          = merge(var.tags,{Name="${var.tags.Name}_public"})
    public_route_table_tags     = merge(var.tags,{Name="${var.tags.Name}_public"})
}

# Create the security group to handle connections from inbound according to a predefined rule (like http-80)
module "security_group_webserver" {
    source              = "terraform-aws-modules/security-group/aws"
    name                = "web-server"
    vpc_id              = module.vpc.vpc_id
    create_sg           = var.ingress_rule != ""

    # outbounds : open to all tcp connections
    egress_with_cidr_blocks    = [ 
        {
            rule="all-tcp"
            cidr_blocks="0.0.0.0/0"
        }
    ]

    # inbound : accept a predefined rule (see here : https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/rules.tf)
    ingress_with_cidr_blocks = [
        {
            rule=var.ingress_rule
            cidr_blocks="0.0.0.0/0"
        }
    ]

    tags                = merge(var.tags,{Name="${var.tags.Name}_sg"})
}

# Create a Security group for task definition & EFS mount access point
# module "security_group_nfs" {
#     source              = "terraform-aws-modules/security-group/aws"
#     name                = "allow NFS"
#     vpc_id              = module.vpc.vpc_id
#     create_sg           = var.ingress_rule != ""

#     # outbounds : open to all tcp connections
#     egress_with_cidr_blocks    = [ 
#         {
#             rule="all-all"
#             cidr_blocks="0.0.0.0/0"
#         }
#     ]

#     # inbound : accept a predefined rule (see here : https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/rules.tf)
#     ingress_with_cidr_blocks = [
#         {
#             rule="nfs-tcp"
#             cidr_blocks="0.0.0.0/0"
#         }
#     ]

#     tags                = merge(var.tags,{Name="${var.tags.Name}_sg"})
# }

# Create resources for a persistant storage based on EFS
module "efs" {
    source                  = "./modules/EFS"

    root_directories        = local.efs_volumes_path_to_create
    vpc_id                  = module.vpc.vpc_id
    source_sg_id            = module.security_group_webserver.security_group_id
    mount_points_subnets_id = module.vpc.private_subnets

    tags                    = merge(var.tags,{Name="${var.tags.Name}_storage"})
}

# Create a cluster + a service + task definitions with or without a volume on EFS
module "ecs" {
    source = "./modules/ECS"

    vpc_id                          = module.vpc.vpc_id
    subnets_ids                     = module.vpc.public_subnets
    app_security_group_ids          = [module.security_group_webserver.security_group_id]

    desired_count_task_def_to_run   = var.desired_tasks_to_run
    assign_public_ip                = var.assign_public_ip

    efs_security_group_id           = module.efs.security_group_id
    efs_policy_document             = module.efs.iam_policy_json_document

    service_name                    = "service_${var.tags.Name}" 
    
    container_definitions_list      = var.containers_definition
    
    # extract volumes (persistant or ephemeral/bind) from the task definitions and build a list of objects with appropriate keys ("name" only is required for bind mounts)
    container_bind_volumes          = [for prop in matchkeys(flatten(var.containers_definition[*].mountPoints[*].sourceVolume),flatten(var.containers_definition[*].mountPoints[*].persistant_storage),[false]):{"name"=prop}]
    
    # for EFS mounting points, we need to get the access points ID created for each container path
    container_efs_volumes           = [for m_point in flatten(var.containers_definition[*].mountPoints):
        {

            name                        = m_point.sourceVolume
            efs_volume_configuration    = [{
                file_system_id              = module.efs.efs_id
                root_directory              = m_point.containerPath #"/var/jenkins_home"
                transit_encryption          = "ENABLED"
                authorization_config        = [{
                    access_point_id             = join("",[for ap in module.efs.path_access_point_ids: ap.id if ap.path == m_point.containerPath])
                    iam                         = "ENABLED"
                }]
            }]
        } 
        if m_point.persistant_storage
    ]
    tags                            = var.tags
}