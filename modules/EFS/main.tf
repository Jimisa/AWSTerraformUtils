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

data "aws_security_groups" "for_app" { 
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
      values    = [ 80, 8080 ]
    }
}

# Create a Security group for task definition & EFS mount access point
resource "aws_security_group" "for_efs" {
    name    = "allow NFS"
    vpc_id  = data.aws_vpc.selected.id
    tags = {
      "Type" = "NFS"
    }
}

resource "aws_security_group_rule" "NFS" {
    type                      = "ingress"
    from_port                 = 2049
    to_port                   = 2049
    protocol                  = "tcp"
    security_group_id         = aws_security_group.for_efs.id
    source_security_group_id  = tolist(data.aws_security_groups.for_app.ids)[0]
}

resource "aws_security_group_rule" "out" {
    type                      = "egress"
    from_port                 = 0
    to_port                   = 0
    protocol                  = "-1"
    cidr_blocks               = [ "0.0.0.0/0" ]
    security_group_id         = aws_security_group.for_efs.id
}

resource "aws_efs_file_system" "this" {
  creation_token    = "${var.project_name}_persistant_storage"
  lifecycle_policy {
    transition_to_ia  = "AFTER_30_DAYS"
  }
  encrypted         = true

}

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id
  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_mount_target" "this" {
    count       = length(data.aws_subnet_ids.private.ids)
    # for_each = data.aws_subnet_ids.private.ids
    file_system_id = aws_efs_file_system.this.id
    subnet_id = tolist(data.aws_subnet_ids.private.ids)[count.index] # each.value
    security_groups = [ aws_security_group.for_efs.id ]
}

resource "aws_efs_access_point" "this" {
    file_system_id = aws_efs_file_system.this.id  
    posix_user {
        gid = 1000
        uid = 1000
    }
    root_directory {
        path = var.root_directory
        creation_info {
          owner_gid = 1000
          owner_uid = 1000
          permissions = 755
        }
    }        
}
