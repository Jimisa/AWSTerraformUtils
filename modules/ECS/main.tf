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
        resources   = [ "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:*" ]
    } 
}

resource "aws_iam_role_policy" "create-log-group" {
    name    = "CreateLogGroupPolicy"
    role    = aws_iam_role.task_exec_role.id
    policy  = data.aws_iam_policy_document.create_log_group.json
}

resource "aws_iam_role" "app_role" {
    name                = "AppRole"
    assume_role_policy  = file("${path.module}/ecs-tasks-trust-policy.json")
}

resource "aws_iam_role_policy" "efs_client" {
    name    = "EFSClientReadWritePolicy"
    role    = aws_iam_role.app_role.id
    policy  = var.efs_policy_document
}

resource "aws_ecs_cluster" "this" {
    name                = "${var.tags.Name}_cluster"
    capacity_providers  = var.capacity_providers
}

resource "aws_ecs_task_definition" "this" {
    family                      = "family_${var.service_name}"
    requires_compatibilities    = [ "FARGATE", "EC2" ]
    network_mode                = "awsvpc"

    cpu                         = var.desired_cpu
    memory                      = var.desired_memory
    
    execution_role_arn          = aws_iam_role.task_exec_role.arn
    task_role_arn               = aws_iam_role.app_role.arn
    
    container_definitions       = jsonencode(var.container_definitions_list)
    
    # dynamic block, created if either containers_efs_volumes or container_bind_volumes is filled
    dynamic "volume" {
        for_each = concat(var.container_efs_volumes,var.container_bind_volumes)
        content {
            name    = volume.value.name
            dynamic "efs_volume_configuration" {
                for_each = lookup(volume.value,"efs_volume_configuration",[])
                content {
                    file_system_id          = lookup(efs_volume_configuration.value,"file_system_id",null)
                    root_directory          = lookup(efs_volume_configuration.value,"root_directory",null)
                    transit_encryption      = lookup(efs_volume_configuration.value,"transit_encryption",null)
                    transit_encryption_port = lookup(efs_volume_configuration.value,"transit_encryption_port",null)
                    dynamic "authorization_config" {
                        for_each = lookup(efs_volume_configuration.value,"authorization_config",[])
                        content {
                            access_point_id = lookup(authorization_config.value,"access_point_id",null)
                            iam             = lookup(authorization_config.value,"iam",null)
                        }
                    }
                }
            }
        }
    }
}

resource "aws_ecs_service" "db" {
    platform_version        = "1.4.0"
    name                    = "${var.tags.Name}_service"
    cluster                 = aws_ecs_cluster.this.id
    desired_count           = var.desired_count_task_def_to_run
    force_new_deployment    = true
    launch_type             = "FARGATE"
    task_definition         = aws_ecs_task_definition.this.arn

    network_configuration {
      subnets           = var.subnets_ids
      security_groups   = var.app_security_group_ids
      assign_public_ip  = var.assign_public_ip
    }
    deployment_controller {
      type = "ECS"
    }

    # lifecycle {
    #     ignore_changes = [
    #       desired_count
    #     ]
    # }  
}