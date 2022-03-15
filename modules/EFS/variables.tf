variable "root_directories" {
    description = "defines the path in the container mounted to the EFS - MANDATORY"
    type        = list(string)
}

variable "vpc_id" {
    description = "ID of the VPC to access the EFS"
    type        = string
}

variable "source_sg_id" {
    description = "ID of the Security Group bound to the resource that can access the EFS" 
    type        = string 
}

variable "inbound_port" {
    description = "Port to open in the EFS security group"
    type        = number
    default     = 2049
}

variable "mount_points_subnets_id" {
    description = "list of subnets id for mounting points "
    type        = list(string)  
}

variable "tags" {
    description = "list of tags to be added to all resources"
    type        = map(string)
}
