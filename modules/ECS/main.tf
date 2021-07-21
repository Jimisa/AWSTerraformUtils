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
    profile     = "default"
    region      = var.region
    
    default_tags {
        tags = {
            Project = var.project_name
            Environment = var.environment
        }
    }
}

data "aws_vpc" "selected" {
    filter {
      name      = "tag:Project"
      values    = [ var.project_name ]
    }

    filter {
      name      = "tag:Environment"
      values    = [ var.environment ]
    }  
}

data "aws_subnet_ids" "all" {
    vpc_id = data.aws_vpc.selected.id

    filter {
      name      = "tag:Project"
      values    = [ var.project_name ]
    }

    filter {
      name      = "tag:Environment"
      values    = [ var.environment ]
    }
}

data "aws_subnet_ids" "private" {
    vpc_id = data.aws_vpc.selected.id

    filter {
      name      = "tag:Project"
      values    = [ var.project_name ]
    }

    filter {
      name      = "tag:Environment"
      values    = [ var.environment ]
    }
    
    filter {
      name      = "tag:Tier"
      values    = [ "Private" ]
    }
}

data "aws_security_group" "app" {

    filter {
        name      = "tag:Project"
        values    = [ var.project_name ]
    }

    filter {
        name      = "tag:Environment"
        values    = [ var.environment ]
    }
    
    filter {
        name      = "tag:Type"
        values    = [ "app" ]
    }
}

data "aws_security_group" "for_efs" {

    filter {
        name      = "tag:Project"
        values    = [ var.project_name ]
    }

    filter {
        name      = "tag:Environment"
        values    = [ var.environment ]
    }
    
    filter {
        name      = "ip-permission.to-port"
        values    = [ 2049 ]
    }
}

data "aws_efs_file_system" "volume" {
    creation_token = "${var.project_name}_persistant_storage"
}

data "aws_efs_access_points" "selectedlist" {
    file_system_id = data.aws_efs_file_system.volume.id
}

# TEST : already existing role
# data "aws_iam_role" "for_ecs" {
#     name = "ecsTaskExecutionRole"
# }

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "task_exec_role" {
    name = "TaskExecRole"
    assume_role_policy = file("${path.module}/ecs-tasks-trust-policy.json")
}

resource "aws_iam_role_policy_attachment" "task_exec_policy" {
    role        = aws_iam_role.task_exec_role.name
    policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" 
}

data "aws_iam_policy_document" "create_log_group" {
    version = "2012-10-17"
    statement {
        effect      = "Allow"
        actions     = [ "logs:CreateLogGroup" ]
        resources    = [ "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:*" ]
    } 
}

resource "aws_iam_role_policy" "create-log-group" {
    name = "CreateLogGroupPolicy"
    role = aws_iam_role.task_exec_role.id
    policy = data.aws_iam_policy_document.create_log_group.json
}

resource "aws_iam_role" "app_role" {
    name = "AppRole"
    assume_role_policy = file("${path.module}/ecs-tasks-trust-policy.json")
}

data "aws_iam_policy_document" "app-task-role" {
    version = "2012-10-17"
    statement {
            effect      = "Allow"
            resources    = [ data.aws_efs_file_system.volume.arn ]
            actions     = [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ]
            condition {
                test    = "StringEquals"
                variable  = "elasticfilesystem:AccessPointArn"
                values = [tolist(data.aws_efs_access_points.selectedlist.arns)[0]]
            }
    }
}

resource "aws_iam_role_policy" "efs_client" {
    name = "EFSClientReadWritePolicy"
    role = aws_iam_role.app_role.id
    policy = data.aws_iam_policy_document.app-task-role.json
}

resource "aws_ecs_cluster" "this" {
    name = "${var.project_name}_cluster"
    capacity_providers = var.capacity_providers

}

resource "aws_ecs_task_definition" "jenkins_task_def" {
    family                      = "${var.project_name}"
    requires_compatibilities    = [ "FARGATE", "EC2" ]
    network_mode                = "awsvpc"
    cpu                         = var.desired_cpu
    memory                      = var.desired_memory
    execution_role_arn          = aws_iam_role.task_exec_role.arn # data.aws_iam_role.for_ecs.arn 
    task_role_arn               = aws_iam_role.app_role.arn
    container_definitions       = jsonencode([
        {
            name            = "jenkins"
            image           = var.app_container_image
            #cpu             = var.desired_cpu
            #memory          = var.desired_memory
            portMappings    = [
                {
                    containerPort   = 8080
                }
            ]
            mountPoints     = [{
                containerPath   = var.root_directory
                sourceVolume    = "jenkinshome"
                readOnly        = false
            }]
            logConfiguration    = {
                logDriver   = "awslogs",
                options     = {
                    awslogs-create-group    = "true"
                    awslogs-group           = "awslog-jenkins"
                    awslogs-region          = var.region
                    awslogs-stream-prefix   = "awslogs-${var.project_name}"
                }
            }
            readonlyRootFilesystem = false
        }
    ])

    volume {
        name        = "jenkinshome"
        # host_path   = var.root_directory
        efs_volume_configuration {
          file_system_id            = data.aws_efs_file_system.volume.id
          root_directory            = var.root_directory
          transit_encryption        = "ENABLED"
          # transit_encryption_port   = 2049
          authorization_config {
            access_point_id = tolist(data.aws_efs_access_points.selectedlist.ids)[0]
            iam           = "ENABLED"
          }          
        }
    }
}

resource "aws_ecs_service" "db" {
    platform_version        = "1.4.0"
    name                    = "${var.project_name}_service"
    cluster                 = aws_ecs_cluster.this.id
    desired_count           = 0
    force_new_deployment    = true
    launch_type             = "FARGATE"
    task_definition         = aws_ecs_task_definition.jenkins_task_def.arn

    network_configuration {
      subnets           = data.aws_subnet_ids.private.ids
      security_groups   = [ data.aws_security_group.app.id ]
      assign_public_ip  = true # TEST false
    }
    deployment_controller {
      type = "ECS"
    }

    lifecycle {
        ignore_changes = [
          desired_count
        ]
    }  
}