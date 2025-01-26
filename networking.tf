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

  enable_ipv6 = true

  public_subnet_ipv6_prefixes  = [0, 1]
  private_subnet_ipv6_prefixes = [2, 3]

  public_subnet_assign_ipv6_address_on_creation  = true
  private_subnet_assign_ipv6_address_on_creation = true

  public_subnet_enable_dns64  = false
  private_subnet_enable_dns64 = false

  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
