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

variable "cidr_main_vpc" {
    description   = "network IP range with CIDR notation (0.0.0.0/0) for main VPC"
    default       = "10.1.0.0/16"
    type          = string
}

variable "cidr_subnet_1" {
    description   = "network IP range with CIDR notation (0.0.0.0/0) for public subnet 1"
    default       = "10.1.1.0/24"
    type          = string
}

variable "cidr_subnet_2" {
    description   = "network IP range with CIDR notation (0.0.0.0/0) for public subnet 2"
    default       = "10.1.2.0/24"
    type          = string
}