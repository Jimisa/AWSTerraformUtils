variable "project_name" {
  description   = "Name for tagging all ressources"
  default       = "demo"
  type          = string
}

variable "environment" {
  description = "status of the ressourecs (test, staging, production...)"
  default     = "prod"
  type        = string
}


variable "region" {
  description   = "AWS region to create ressources"
  default       = "eu-central-1"
  type          = string
}

variable "capacity_providers" {
  description   = "type of providers associated with the cluster"
  default       = [ "FARGATE" ]
  type          = list(string)
}

# CPU value 	Memory value
# 256 (.25 vCPU) 	512 MB, 1 GB, 2 GB
# 512 (.5 vCPU) 	1 GB, 2 GB, 3 GB, 4 GB
# 1024 (1 vCPU) 	2 GB, 3 GB, 4 GB, 5 GB, 6 GB, 7 GB, 8 GB
# 2048 (2 vCPU) 	Between 4 GB and 16 GB in 1 GB increments
# 4096 (4 vCPU) 	Between 8 GB and 30 GB in 1 GB increments

variable "desired_cpu" {
  description   = "cpu for the task definition "
  default       = 256
  type          = number
}

variable "desired_memory" {
  description   = "memory for the task definition "
  default       = 512
  type          = number
}

variable "root_directory" {
  description   = "path for the volume mount"
  default       = "/var/jenkins_home"
  type          = string
}

variable "service_name" {
  description   = "name of the ECS service"
  default       = "jenkins_service"
  type          = string
}

variable "app_container_image" {
  description = "image for the application"
  default = "jenkins/jenkins:lts-jdk11"
  type = string
}

