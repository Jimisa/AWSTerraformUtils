# Create private subnet with Terraform : https://hands-on.cloud/terraform-managing-aws-vpc-creating-private-subnets/

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

resource "aws_vpc" "main" {
    cidr_block = var.cidr_main_vpc
    enable_dns_hostnames = true # to let ECS service access EFS via AP seehttps://aws.amazon.com/fr/premiumsupport/knowledge-center/ecs-pull-container-error/
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.cidr_subnet_1
    availability_zone = "${var.region}a"
    tags = {
      "Tier" = "Public"
    }
}

resource "aws_subnet" "private" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.cidr_subnet_2
    availability_zone = "${var.region}b"

    tags = {
      "Tier" = "Private"
    }

    depends_on = [
      aws_internet_gateway.this
    ]
}

resource "aws_internet_gateway" "this" {
    vpc_id =  aws_vpc.main.id
}

# resource "aws_eip" "this" {
#     vpc = true

#     depends_on = [
#       aws_internet_gateway.this
#     ]
# }

# resource "aws_nat_gateway" "this" {
#     allocation_id   = aws_eip.this.id
#     subnet_id       = aws_subnet.public.id
# }

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.this.id
    }
}

resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "nat" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        # TEST -> private subnet going to public
        gateway_id = aws_internet_gateway.this.id
        # nat_gateway_id = aws_nat_gateway.this.id
    }
}

resource "aws_route_table_association" "nat" {
    subnet_id = aws_subnet.private.id
    route_table_id = aws_route_table.nat.id
}

resource "aws_security_group" "app" {
    name    = "security group for app"
    vpc_id  = aws_vpc.main.id

    # ingress {
    #     description = "Inbound on EFS access mount point"
    #     from_port   = 2049
    #     to_port     = 2049
    #     protocol    = "tcp"
    #     cidr_blocks  = [ "0.0.0.0/0" ]
    # }

    tags = {
      "Type" = "app"
    }
}

resource "aws_security_group_rule" "TCP8080" {
    type                = "ingress"
    from_port           = 8080
    to_port             = 8080
    protocol            = "tcp"
    cidr_blocks         = [ "0.0.0.0/0"]
    security_group_id   = aws_security_group.app.id
}

resource "aws_security_group_rule" "TCP80" {
    type                = "ingress"
    from_port           = 80
    to_port             = 80
    protocol            = "tcp"
    cidr_blocks         = [ "0.0.0.0/0"]
    security_group_id   = aws_security_group.app.id
}

resource "aws_security_group_rule" "out" {
    type                = "egress"
    from_port           = 0
    to_port             = 0
    protocol            = "-1"
    cidr_blocks         = [ "0.0.0.0/0"]
    security_group_id   = aws_security_group.app.id
}