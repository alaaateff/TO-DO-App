variable "region" {
    type = string
    default = "us-east-1"
}
variable "cidr_block"{}
variable "pub-sub-count" {}
variable "pub-sub-cidr" {
    type = list(string)
}
variable "pub-az" {
    type = list(string)
}
variable "priv-sub-count" {}
variable "priv-sub-cidr" {
    type = list(string)
}
variable "priv-az" {
    type = list(string)
}
variable "eks-sg" {}

#eks

variable "cluster-name" {}
variable "cluster-version" {}
variable "endpoint-private-access" {}
variable "endpoint-public-access" {}
variable "addons" {
    type = list(object({
    name    = string
    version = string
  }))
}
variable "desired_capacity_on_demand" {}
variable "min_capacity_on_demand" {}
variable "max_capacity_on_demand" {}
variable "ondemand_instance_types" {}
variable "desired_capacity_spot" {}
variable "min_capacity_spot" {}
variable "max_capacity_spot" {}
variable "spot_instance_types" {}
variable "db_username" {}
variable "db_password" {}
