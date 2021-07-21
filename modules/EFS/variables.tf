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
    default       = "us-central-1"
    type          = string
}

variable "root_directory" {
    description = "defines the path in the container mounted to the EFS"
    default     = "/var/jenkins_home"
    type        = string
}