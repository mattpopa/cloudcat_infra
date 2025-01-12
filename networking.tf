module "dev_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.17.0"

  name = "dev"
  cidr = local.dev_cidr

  azs = local.azs
  private_subnets = [
    cidrsubnet(local.dev_cidr, 4, 0),
    cidrsubnet(local.dev_cidr, 4, 2),
  ]
  public_subnets = [
    cidrsubnet(local.dev_cidr, 4, 1),
    cidrsubnet(local.dev_cidr, 4, 3),
  ]

  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
