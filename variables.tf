variable "region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "172.20.0.0/16"
}

variable "subnet_cidr_a" {
  description = "CIDR block for subnet A."
  type        = string
  default     = "172.20.1.0/24"
}

variable "subnet_cidr_b" {
  description = "CIDR block for subnet B."
  type        = string
  default     = "172.20.2.0/24"
}

variable "availability_zone_a" {
  description = "Availability zone for subnet A."
  type        = string
  default     = "ap-southeast-1a"
}

variable "availability_zone_b" {
  description = "Availability zone for subnet B."
  type        = string
  default     = "ap-southeast-1b"
}

# Add more variables as needed
