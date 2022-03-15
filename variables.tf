variable "region" {
    type = string
}

variable "cidr_main_vpc" {
    type    = string
    default =  "10.1.0.0/16"
}

variable "public_subnets" {
    type    = list(string)
    default = [ "10.1.1.0/24","10.1.3.0/24"]
}

variable "private_subnets" {
    type    = list(string)
    default = [ "10.1.2.0/24" ]
}

variable "enable_nat" {
    type    = bool
    default = true
}

variable "ingress_rule" {
    type        = string
    description = "Accept one and only one predefined rule from https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/rules.tf "
}

variable "assign_public_ip" {
    type = bool
    description = "if true, a public IP will be provided to access to the service task"
}

variable "desired_tasks_to_run" {
    type = number
    description = "set the number of tasks from tasks def to deploy in the cluster"
}

variable "containers_definition" {
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
    description = "list of JSON task definitions. See AWS doc for parameters and objects. \"persistant_storage\" is the only additional key and must be filled to create a EFS for persistant volume"
}

variable "tags" {
    type    = map(string)
    default = {
      "Name"    = "demo"
      "Env"     = "dev"
    }
}