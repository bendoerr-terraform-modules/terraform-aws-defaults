module "label_network" {
  source  = "bendoerr-terraform-modules/label/null"
  version = "0.5.0"
  context = var.context
  name    = "ntwrk"
}

locals {
  network_nameless_tags = { for k, v in module.label_network.tags : k => v if k != "Name" }
}

locals {
  # IPv6 configuration
  enable_ipv6            = var.network.ip_mode == "dual-stack" || var.network.ip_mode == "ipv6-only"
  ipv6_only              = var.network.ip_mode == "ipv6-only"
  subnet_count           = length(var.network.subnets)
  public_ipv6_prefixes   = local.enable_ipv6 ? [for i in range(local.subnet_count) : i] : []
  private_ipv6_prefixes  = local.enable_ipv6 ? [for i in range(local.subnet_count) : i + local.subnet_count] : []
  effective_enable_nat   = var.network.enable_nat && !local.ipv6_only
  create_egress_only_igw = local.enable_ipv6
}

module "vpc_default" {
  source     = "terraform-aws-modules/vpc/aws"
  version    = "6.6.0"
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
  # For IPv6-only mode, NAT gateway is not needed as egress-only IGW is used
  enable_nat_gateway     = local.effective_enable_nat
  single_nat_gateway     = var.network.one_nat
  one_nat_gateway_per_az = true
  enable_dns_hostnames   = true

  # IPv6 Configuration
  enable_ipv6                                    = local.enable_ipv6
  public_subnet_ipv6_prefixes                    = local.public_ipv6_prefixes
  private_subnet_ipv6_prefixes                   = local.private_ipv6_prefixes
  public_subnet_ipv6_native                      = local.ipv6_only
  private_subnet_ipv6_native                     = local.ipv6_only
  public_subnet_assign_ipv6_address_on_creation  = local.enable_ipv6
  private_subnet_assign_ipv6_address_on_creation = local.enable_ipv6
  create_egress_only_igw                         = local.create_egress_only_igw

  # Explicitly turn off DNS64 — the vpc module turns it on by default when
  # enable_ipv6 = true (since v4.0.1), but DNS64 silently breaks connectivity
  # to IPv4-only services when NAT64 is not provisioned. This module does not
  # provision NAT64, so DNS64 must be off to avoid misdirecting DNS responses
  # toward a non-existent NAT64 gateway.
  public_subnet_enable_dns64  = false
  private_subnet_enable_dns64 = false

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

output "vpc_ipv6_cidr_block" {
  value       = local.enable_ipv6 ? module.vpc_default.vpc_ipv6_cidr_block : null
  description = "The IPv6 CIDR block assigned to the VPC"
}

output "vpc_public_subnet_ipv6_cidr_blocks" {
  value       = local.enable_ipv6 ? module.vpc_default.public_subnets_ipv6_cidr_blocks : []
  description = "List of IPv6 CIDR blocks for public subnets"
}

output "vpc_private_subnet_ipv6_cidr_blocks" {
  value       = local.enable_ipv6 ? module.vpc_default.private_subnets_ipv6_cidr_blocks : []
  description = "List of IPv6 CIDR blocks for private subnets"
}

output "vpc_egress_only_internet_gateway_id" {
  value       = local.create_egress_only_igw ? module.vpc_default.egress_only_internet_gateway_id : null
  description = "The ID of the egress-only Internet Gateway"
}
