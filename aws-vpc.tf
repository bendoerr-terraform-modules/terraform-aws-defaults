module "label_network" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "0.4.2"
  context = var.context
  name    = "ntwrk"
}

locals {
  network_nameless_tags = { for k, v in module.label_network.tags : k => v if k != "Name" }
}

module "vpc_default" {
  source     = "terraform-aws-modules/vpc/aws"
  version    = "5.12.0"
  create_vpc = true

  name = module.label_network.id
  tags = local.network_nameless_tags

  cidr            = var.network.cidr
  azs             = var.network.subnets.*.az
  public_subnets  = var.network.subnets.*.public
  private_subnets = var.network.enable_private ? var.network.subnets.*.private : []

  public_subnet_suffix  = "public"
  private_subnet_suffix = "private"

  # Disable Private Subnet NAT Gateway unless it's needed
  # NAT Gateways are expensive, between the need for an EIP, the base cost and
  # per GB cost of data, disable them until the private networks actually need
  # to use them.
  enable_nat_gateway     = var.network.enable_nat
  single_nat_gateway     = var.network.one_nat
  one_nat_gateway_per_az = true
  enable_dns_hostnames   = true
  enable_ipv6            = false

  public_dedicated_network_acl  = false
  private_dedicated_network_acl = false

  public_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]

  public_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]

  private_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = var.network.cidr
    },
  ]

  private_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = var.network.cidr
    },
  ]
}

output "vpc_id" {
  value = module.vpc_default.vpc_id
}

output "vpc_azs" {
  value = module.vpc_default.azs
}

output "vpc_public_subnet_ids" {
  value = module.vpc_default.public_subnets
}

output "vpc_private_subnet_ids" {
  value = module.vpc_default.private_subnets
}
