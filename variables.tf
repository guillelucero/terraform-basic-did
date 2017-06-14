variable name {
  default = "my_env"
}

variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-west-2"
}
variable aws_key_name {}

#VPC settings
variable "cidr" {}
variable "enable_dns_hostnames" {
  default     = true
}

variable "enable_dns_support" {
  default     = true
}

variable "public_subnets" {
  default     = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

variable "private_subnets" {
  default     = ["10.0.50.0/24", "10.0.60.0/24", "10.0.70.0/24"]
}

variable "azs" {
  default     = ["us-west-2a","us-west-2b", "us-west-2c"]
}

variable "ami" {
    description = "Amazon ECS CoreOS AMI"
    default = {
        us-west-1 = "ami-2a47644a"
        us-west-2 = "ami-f4d4b694"
    }
}