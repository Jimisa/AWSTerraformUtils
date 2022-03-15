variable "capacity_providers" {
  description = "type of providers associated with the cluster"
  default     = [ "FARGATE" ]
  type        = list(string)
}

# CPU value 	Memory value
# 256 (.25 vCPU) 	512 MB, 1 GB, 2 GB
# 512 (.5 vCPU) 	1 GB, 2 GB, 3 GB, 4 GB
# 1024 (1 vCPU) 	2 GB, 3 GB, 4 GB, 5 GB, 6 GB, 7 GB, 8 GB
# 2048 (2 vCPU) 	Between 4 GB and 16 GB in 1 GB increments
# 4096 (4 vCPU) 	Between 8 GB and 30 GB in 1 GB increments

variable "desired_cpu" {
    description = "cpu for the task definition "
    default     = 256
    type        = number
}

variable "desired_memory" {
    description = "memory for the task definition "
    default     = 512
    type        = number
}

variable "service_name" {
    description = "name of the ECS service"
    type        = string
}

variable "vpc_id" {
    description = "Id of the vpc" 
    type        = string
}

variable "subnets_ids" {
    description = "list of the vpc subnets that host the tasks"
    type        =  list(string)
}

variable "app_security_group_ids" {
    description = "Security groups for the ECS service"
    type        = list(string)
    default = []
}

variable "efs_security_group_id" {
    description = "Security group for the EFS mounting point"
    type        = string
    default = null
}

variable "efs_policy_document" {
    description = "JSON document to add for access to task definition"
    type        = string
}

variable "container_definitions_list" {
    description = "list of objects describing task definitions"
    type        = any
    # (object({
    #     name                    = string
    #     image                   = string
    #     cpu                     = number
    #     memory                  = number
    #     mountPoints             = list(object({
    #         containerPath           = string
    #         sourceVolume            = string
    #         readOnly                = bool
    #         persistant_storage      = bool
    #     }))
    #     portMappings            = list(object({
    #         containerPort           = number
    #         hostPort                = number
    #     }))
    #     logConfiguration        = object({
    #         logDriver               = string
    #         options                 = map(string)
    #     })
    #     readonlyRootFilesystem  = bool
    # }))
}

variable "container_efs_volumes" {
    description = "list of container volumes"
    type = list(object({
        name                        = string
        efs_volume_configuration    = list(object({
            file_system_id              = string
            root_directory              = string
            transit_encryption          = string
            authorization_config        = list(map(string))
        }))
    }))
}

variable "container_bind_volumes" {
    description = "list of bind mount"
    type        = list(object({
        name        = string
    }))
  
}

variable "desired_count_task_def_to_run" {
    description = "set to 0 if no task should be runnning. Otherwise set any number value"
    type        = number
    default     = 0
}

variable "assign_public_ip" {
    description = "if true a public IP will be set as external access to the service"
    type        = bool
    default     = false
}

variable "tags" {
    description = "list of tags to be added to all resources"
    type        = map(string)
}