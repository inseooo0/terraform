variable "region" {
  type = string
  default = "ap-northeast-2"
}

variable "env_suffix" {
  type = string
}

variable "az_count" {
  type    = number
  default = 2
}

variable "app_name" {
  type = string
}

variable "host_port" {
  type = number
  default = 8080
}

variable "container_port" {
  type = number
  default = 8080
}

variable "scaling_max_capacity" {
  type = number
  default = 3
}

variable "scaling_min_capacity" {
  type = number
  default = 1
}

variable "cpu_or_memory_limit" {
  type = number
  default = 70
}

variable "tpl_path" {
  type = string
  default = "service.config.json.tpl"
}

variable "account_id" {
  type = string
}

variable "elb_account_id" {
  type = string
  default = "600734575887"
}
