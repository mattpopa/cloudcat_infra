locals {
  base_domain     = "cloudcat.digital"
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
  default     = "billing@cloudcat.digital"
}
