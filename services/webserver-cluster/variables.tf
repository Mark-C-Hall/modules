variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "server_port" {
  description = "Server Port"
  type        = number
  default     = 8080
}

locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket to store the remote state file"
  type        = string

}

variable "db_remote_state_key" {
  description = "The name of the S3 key to store the remote state file"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instance to run"
  type        = string
}

variable "min_size" {
  description = "The minimum number of instances to run"
  type        = number
}

variable "max_size" {
  description = "The maximum number of instances to run"
  type        = number
}
