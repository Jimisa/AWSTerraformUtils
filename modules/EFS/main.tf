resource "aws_security_group" "for_efs" {
    #count   = var.create ? 1 : 0
    name    = "allow NFS"
    vpc_id  = var.vpc_id
    tags    = merge(var.tags, {"Type" = "NFS"})
}

resource "aws_security_group_rule" "NFS" {
    #count                     = var.create ? 1 : 0
    type                      = "ingress"
    from_port                 = var.inbound_port
    to_port                   = var.inbound_port
    protocol                  = "tcp"
    security_group_id         = aws_security_group.for_efs.id
    source_security_group_id  = var.source_sg_id
}

resource "aws_security_group_rule" "out" {
    #count                     = var.create ? 1 : 0
    type                      = "egress"
    from_port                 = 0
    to_port                   = 0
    protocol                  = "-1"
    cidr_blocks               = [ "0.0.0.0/0" ]
    security_group_id         = aws_security_group.for_efs.id
}

resource "aws_efs_file_system" "this" {
    #count             = var.create ? 1 : 0
    creation_token    = "${var.tags.Name}_persistant_storage"

    lifecycle_policy {
      transition_to_ia  = "AFTER_30_DAYS"
    }
    encrypted           = true
    tags                = merge(var.tags,{"Name" = "${var.tags.Name}_persistant_storage"})
}

resource "aws_efs_backup_policy" "this" {
  #count           = var.create ? 1 : 0
  file_system_id  = aws_efs_file_system.this.id
  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_mount_target" "this" {
    count           = length(var.mount_points_subnets_id)
    file_system_id  = aws_efs_file_system.this.id
    subnet_id       = tolist(var.mount_points_subnets_id)[count.index]
    security_groups = [ aws_security_group.for_efs.id ]
}

resource "aws_efs_access_point" "this" {
    count           = length(var.root_directories)
    file_system_id  = aws_efs_file_system.this.id  
    posix_user {
        uid = 1000
        gid = 1000
    }
    root_directory {
        path = var.root_directories[count.index]
        creation_info {
          owner_gid   = 1000
          owner_uid   = 1000
          permissions = 755
        }
    }
    tags            = merge(var.tags,{"path"=var.root_directories[count.index]})
}

data "aws_iam_policy_document" "app_task_role" {
    #count           = var.create ? 1 : 0
    version = "2012-10-17"
    statement {
            effect          = "Allow"
            resources       = [ aws_efs_file_system.this.arn ]
            actions     = [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ]
            condition {
                test    = "StringEquals"
                variable  = "elasticfilesystem:AccessPointArn"
                values = aws_efs_access_point.this[*].id
            }
    }
}