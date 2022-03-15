variable "containers_definition" {
    type        = list(object({
        name                = string
        image               = string
        cpu                 = number
        memory              = number
        mountPoints         = list(object({
          containerPath = string
          sourceVolume  = string
          readOnly      = bool
          persistant_storage  = bool
        }))
        portMappings        = list(object({
          containerPort = number
          hostPort      = number
        }))
        logConfiguration    = object({
            logDriver   = string
            options     = map(string)
        })
        readonlyRootFilesystem  = bool
    }))
    description = "list of JSON task definition"
}

variable "access_point" {
    type = list(object({
        id = string
        path = string
    }))
}