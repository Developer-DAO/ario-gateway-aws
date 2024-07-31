variable "alias" {
  type        = string
  description = "The alias of the environment"
}

variable "region" {
  type        = string
  description = "The region"
}

variable "account_id" {
  type        = string
  description = "The account id"
}

variable "domain_name" {
  type        = string
  description = "The domain name"
}

variable "subdomain_name" {
  type        = string
  description = "The subdomain name"
}

variable "graphql_ip_allow_list" {
  type        = list(string)
  description = "List of IP's not to rate limit on /graphql endpoint"
  default     = []
}

variable "public_subnets" {
  type        = list(any)
  description = "List of private subnets"
}

variable "private_subnets" {
  type        = list(any)
  description = "List of private subnets"
}

variable "vpc_id" {
  type        = string
  description = "The id of the vpc"
}

variable "vpc_cidr" {
  type        = string
  description = "The cidr of the vpc"
}

variable "instance_type" {
  type        = string
  description = "The instance type"
}

variable "observer_key" {
  type        = string 
  description = "Used to submit observer reports to Arweave"
}