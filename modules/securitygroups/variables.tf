variable "private_vpc_id" {
  type        = string
  description = "VPC ID for private resources"
  default     = ""
}

variable "public_vpc_id" {
  type        = string
  description = "VPC ID for private resources"
  default     = ""
}

variable "ApplicationName" {
  type        = string
  description = ""
  default     = ""
}

variable "EnvironmentName" {
  type        = string
  description = ""
  default     = ""
}

variable "prefix_list_ids"{
  type        = list(string)
  description = ""
}

variable "hydratcpserviceprivate_prefix_list_ids"{
  type        = list(string)
  description = ""
}


variable "public_vpc_cidr"{
  type        = list(string)
  description = ""
}

variable "bastion_ec2_cidrs"{
  type        = list(string)
  description = ""
}

variable "existing_db_cluster_sg" {
  type        = string
  description = ""
}

variable "create_etl_lambda" {
  type       = bool 
}

variable "create_bastion_instance" {
  type        = string
  description = ""
}

variable "private_vpc_cidr" {
  type = list(string)
}
variable "create_xservice" {
  type    = bool
  default = false
}

variable "deploy_redis" {
  type    = bool
  default = true
}
