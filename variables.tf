variable "project_name" {
  description = "Name of the project (prefix for resource naming)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "services" {
  description = "List of services to deploy"
  type = list(object({
    name      = string
    app_port  = number
    repo_name = string
    branch    = string
  }))
}

