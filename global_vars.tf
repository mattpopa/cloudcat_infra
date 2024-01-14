locals {
  base_domain     = "cloudcat.digital"
  gh_pages_domain = "mattpopa.github.io"
  s3_eu_west_2_id = "Z3GKZC51ZF0DB4" # Amazon S3 website endpoints https://docs.aws.amazon.com/general/latest/gr/s3.html
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
}

variable "cloudcat_contact" {
  description = "The email address of the CloudCat contact for this account"
  default     = "matt@cloudcat.digital"
}
