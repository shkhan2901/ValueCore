variable "Prod" {
  default     = "vpc-0b858ad959f8b3033"
  type        = string
  description = "Name of the VPC"
}

variable "region" {
  default     = "us-east-1"
  type        = string
  description = "Region of the VPC"
}


variable "cidr_block" {
  default     = "10.0.0.0/20"
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr_blocks" {
  default     = ["10.0.1.0/25", "10.0.2.0/25"]
  type        = list(any)
  description = "List of public subnet CIDR blocks"
}

variable "private_subnet_cidr_blocks" {
  default     = ["10.0.3.0/25", "10.0.4.0/25", "10.0.5.0/25", "10.0.6.0/25"]
  type        = list(any)
  description = "List of private subnet CIDR blocks"
}

variable "availability_zones" {
  default     = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
  type        = list(any)
  description = "List of availability zones"
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Extra tags to attach to the VPC resources"
}
