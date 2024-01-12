locals  {
  base_domain = "cloudcat.digital"
  gh_pages_domain = "mattpopa.github.io"
  s3_eu_west_2_id = "Z3GKZC51ZF0DB4" # Amazon S3 website endpoints https://docs.aws.amazon.com/general/latest/gr/s3.html
}

variable "cloudcat_contact" {
  description = "The email address of the CloudCat contact for this account"
  default     = "matt@cloudcat.digital"
}
