locals {
  base_domain     = "cloudcat.digital"
  host1           = "stefaniapana.design"
  host2           = "urbanreshape.ro"
  gh_pages_domain = "mattpopa.github.io"
  github_pages_ipv4 = [
    "185.199.108.153",
    "185.199.109.153",
    "185.199.110.153",
    "185.199.111.153"
  ]
  github_pages_ipv6 = [
    "2606:50c0:8000::153",
    "2606:50c0:8001::153",
    "2606:50c0:8002::153",
    "2606:50c0:8003::153"
  ]
  azs = [
    "eu-central-1a",
    "eu-central-1b",
    #"eu-central-1c"
  ]
  dev_cidr = "10.0.0.0/16"
}

variable "cloudcat_contact" {
  description = "The email address of the CloudCat contact for this account"
  default     = "support@cloudcat.digital"
}

variable "instance_type_micro" {
  description = "The instance type to use for the EC2 instance"
  default     = "t3.micro"
}

variable "instance_type_small" {
  description = "The instance type to use for the EC2 instance"
  default     = "t3.small"
}

variable "ami-bkp-1" {
  description = "The AMI ID to use for the EC2 instance"
  default     = "ami-0d26b697dc058bf82"
}

variable "ami-bkp-2" {
  description = "The AMI ID to use for the EC2 instance"
  default     = "ami-0856059115bd424b8"
}