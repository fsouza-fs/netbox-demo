variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "domain_name" {
  type = string
  default = "test.net"
}

variable "ec2_pub_key" {
  type = string
}

variable "netbox-service" {
  type = string
  default = "netbox-service"
}

variable "cluster_name" {
  type = string
  default = "netbox"
}

variable "netbox_container_name" {
  type = string
  default = "netbox"
}

variable "cluster_id" {
  description = "Identifier for the Redis cluster"
  default     = "netbox-redis-cluster"
}

variable "node_type" {
  description = "Instance type for Redis nodes"
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes in the cluster"
  default     = 1
}

variable "netbox_image" {
  default = "docker.io/netboxcommunity/netbox:v4.1-3.0.2"
}

variable "netbox_secret_key" {
  type = string
}

variable "netbox_email" {
  type = string
}

variable "netbox_superuser_name" {
  type = string
}

variable "netbox_superuser_pass" {
  type = string
}

variable "netbox_superuser_email" {
  type = string
}

variable "netbox_db_name" {
  type = string
}

variable "netbox_db_username" {
  type = string
}

variable "netbox_db_password" {
  type = string
}
