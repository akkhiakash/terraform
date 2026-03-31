variable "environment_variables" {
  type = map(string)
  description = "Map of environment variables for the ECS task definition"
}

variable "secrets" {
  type = map(string)
  description = "Map of secrets for the ECS task definition"
}

variable "nginx_image" {
  type        = string
  description = ""
  default     = ""
}

variable "alb_logs_bucket" {
  type        = string
  description = ""
  default     = "" 
}

variable "websockets_image" {
  type        = string
  description = ""
  default     = ""
}

variable "app_image" {
  type        = string
  description = ""
  default     = ""
}

variable "public_vpc_cidr" {
  type        = string
  description = ""
  default     = ""
}

variable "private_vpc_id" {
  type        = string
  description = ""
  default     = ""
}

variable "public_vpc_id" {
  type        = string
  description = ""
  default     = ""
}

variable "alb_service_cert" {
  type        = string
  description = ""
  default     = ""  
}

variable "EnvironmentName" {
  type        = string
  description = ""
  default     = ""
}

variable "ApplicationName" {
  type        = string
  description = ""
  default     = ""
}

variable "aws_region" {
  type        = string
  description = ""
  default     = ""
}

variable "task_role_arn" {
  type        = string
  description = ""
  default     = ""
}

variable "execution_role_arn" {
  type        = string
  description = ""
  default     = ""
}

variable "cpu" {
  type        = string
  description = ""
  default     = ""
}

variable "memory" {
  type        = string
  description = ""
  default     = ""
}

variable "desired_count" {
  type        = string
  description = ""
  default     = ""
}

variable "min_capacity" {
  type        = string
  description = ""
  default     = ""
}

variable "max_capacity" {
  type        = string
  description = ""
  default     = ""
}

variable "django_ALB_websockets_enabled" {
  type = bool
}

variable "private_subnets" {
  type        = list(string)
  description = ""
}

variable "public_subnets" {
  type        = list(string)
  description = ""
}

variable "djangoALBService-sg" {
  type        = list(string)
  description = ""
}

variable "djangoALB-LB-sg" {
  type        = list(string)
  description = ""
}

variable "ecs_cluster_name" {
  type        = string
  description = ""
  default     = ""
}

variable "ecs_cluster_id" {
  type        = string
  description = ""
  default     = ""
}

variable "enable_autoscaling" {
  type        = bool
}


variable "aws_service_discovery_private_dns_namespace" {
  type        = string
  description = ""
  default     = ""
}

# variable "deployment_configuration" {
#   description = "ECS service deployment configuration"
#   type = object({
#     maximum_percent         = number
#     minimum_healthy_percent = number
#     deployment_circuit_breaker = object({
#       enable   = bool
#       rollback = bool
#     })
#   })
#   default = {
#     maximum_percent         = 200
#     minimum_healthy_percent = 50
#     deployment_circuit_breaker = {
#       enable   = true
#       rollback = true
#     }
#   }
# }
# variable "enable_service_discovery_albservice" {
#   type        = bool
#   description = "Enable service discovery for the djangoALB ECS service"
#   default     = false
# }
