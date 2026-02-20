<br/>
<p align="center">
  <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-defaults">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/raw/main/docs/logo-dark.png">
      <img src="https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/raw/main/docs/logo-light.png" alt="Logo">
    </picture>
  </a>

<h3 align="center">Ben's Terraform AWS Account Defaults Module</h3>

  <p align="center">
    This is how I do it.
    <br/>
    <br/>
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-defaults"><strong>Explore the docs »</strong></a>
    <br/>
    <br/>
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/issues">Report Bug</a>
    .
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/issues">Request Feature</a>
  </p>
</p>

[<img alt="GitHub contributors" src="https://img.shields.io/github/contributors/bendoerr-terraform-modules/terraform-aws-defaults?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/graphs/contributors)
[<img alt="GitHub issues" src="https://img.shields.io/github/issues/bendoerr-terraform-modules/terraform-aws-defaults?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/issues)
[<img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/bendoerr-terraform-modules/terraform-aws-defaults?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/pulls)
[<img alt="GitHub workflow: Terratest" src="https://img.shields.io/github/actions/workflow/status/bendoerr-terraform-modules/terraform-aws-defaults/test.yml?logo=githubactions&label=terratest">](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/actions/workflows/test.yml)
[<img alt="GitHub workflow: Linting" src="https://img.shields.io/github/actions/workflow/status/bendoerr-terraform-modules/terraform-aws-defaults/lint.yml?logo=githubactions&label=linting">](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/actions/workflows/lint.yml)
[<img alt="GitHub tag (with filter)" src="https://img.shields.io/github/v/tag/bendoerr-terraform-modules/terraform-aws-defaults?filter=v*&label=latest%20tag&logo=terraform">](https://registry.terraform.io/modules/bendoerr-terraform-modules/defaults/aws/latest)
[<img alt="OSSF-Scorecard Score" src="https://img.shields.io/ossf-scorecard/github.com/bendoerr-terraform-modules/terraform-aws-defaults?logo=securityscorecard&label=ossf%20scorecard&link=https%3A%2F%2Fsecurityscorecards.dev%2Fviewer%2F%3Furi%3Dgithub.com%2Fbendoerr-terraform-modules%2Fterraform-aws-defaults">](https://securityscorecards.dev/viewer/?uri=github.com/bendoerr-terraform-modules/terraform-aws-defaults)
[<img alt="GitHub License" src="https://img.shields.io/github/license/bendoerr-terraform-modules/terraform-aws-defaults?logo=opensourceinitiative">](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/blob/main/LICENSE.txt)

## About The Project

Ben's Terraform AWS Account Defaults Module. Configures various defaults and
network for your AWS account. Non-optionally sets basic account-wide billing
alerts to help avoid run-away costs.

### Defaults

- EC2 Serial Console Access ENABLED by Default
- EBS Default KMS Key set to the AWS Managed KMS Key
- EBS Encryption ENABLED by Default
  - 💸 Note potential costs from KMS @
    [$0.03 per 10,000 requests](https://aws.amazon.com/kms/pricing/)
- ECS EC2 Provisioned Trunking DISABLED by Default
- ECS Container Insights ENABLED by Default
  - 💸 Note potential costs from CloudWatch custom Metrics @
    [$5.40/Service/Month](https://github.com/bendoerr-terraform-modules/terraform-aws-fargate-on-demand/blob/main/modules/service/ecs-cluster.tf#L7-L21)
- IAM Allow Users to Change their own Password ENABLED
- IAM Hard Password Expiry DISABLED
- IAM Max Password Age 90 Days
- IAM Min Password Length 32
- IAM Password Reuse Prevention for the last 5 passwords
- IAM Password Complexity lowercase, uppercase, numbers, symbols all required
- VPC User-specified network
  - 💸🚨Possible configuration costs from NAT Gateways @
    [$32.85/nat/month](https://aws.amazon.com/vpc/pricing/). See more in the
    usage and cost sections below.
  - 💸 Note potential costs from
    [IPv4 Addresses](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/issues/50)

## Usage

The basic defaults are straight forward with variations on network configuration
presenting various options. See the Costs section for the implications of
network topology on cost.

```terraform
module "context" {
  source    = "bendoerr-terraform-modules/context/null"
  version   = "xxx"
  namespace = "btm"
  role      = "production"
  region    = "us-east-1"
  project   = "defaults"
}

module "defaults" {
  source  = "bendoerr-terraform-modules/defaults/aws"
  version = "xxx"
  context = module.context.shared

  budget_monthly_limit = 10.00
  budget_alert_emails  = "alerts@example.com"
  iam_alias_postfix    = "core"

  network = {
    idr           = "10.10.0.0/16"
    enable_nat     = false
    one_nat        = false
    enable_private = false
    subnets = [
      {
        az      = "us-east-1a"
        public  = "10.10.1.0/24"
        private = ""
      },
    ]
  }
}

output "vpc_id" {
  value = module.defaults.vpc_id
}

output "vpc_public_subnet_ids" {
  value = module.defaults.vpc_public_subnet_ids
}
```

### Example Network with Public Subnets Only

[![infracost](https://img.shields.io/endpoint?url=https://dashboard.api.infracost.io/shields/json/6e706676-64ba-43db-97b9-bd92f9272474/repos/4290fbbd-b821-4df7-afde-7addb4d74b8c/branch/0641e65d-bfd2-44c8-9eee-c7511ac75eca/With%2520Public%2520Subnets%2520Only)](https://dashboard.infracost.io/org/bendoerr/repos/4290fbbd-b821-4df7-afde-7addb4d74b8c?tab=settings)

For cost, this is my default network configuration. Each ENI assigned within
this subnet will have an associated IPv4 address attached to it as well. At the
moment this is the most cost-effective solution as there is no charge for active
IPv4 address. 🚨 However, starting in February 2024 active IPv4 addresses will
incur a $0.005/hour charge.

```terraform
network = {
  cidr           = "10.10.0.0/16"
  enable_nat     = false
  one_nat        = false
  enable_private = false
  subnets = [
    {
      az      = "us-east-1a"
      public  = "10.10.1.0/24"
      private = ""
    },
    {
      az      = "us-east-1b"
      public  = "10.10.2.0/24"
      private = ""
    },
    {
      az      = "us-east-1c"
      public  = "10.10.3.0/24"
      private = ""
    },
    {
      az      = "us-east-1d"
      public  = "10.10.4.0/24"
      private = ""
    },
    {
      az      = "us-east-1e"
      public  = "10.10.5.0/24"
      private = ""
    },
    {
      az      = "us-east-1f"
      public  = "10.10.6.0/24"
      private = ""
    },
  ]
}
```

At a base level this configuration incurs no cost. However, take note of future
IPv4 active addresses beginning to cost mention above.

**Important Data Transfer Costs to Keep in Mind:** While the VPC at rest does
not cost, be sure to estimate Data Transfer OUT from AWS to the Internet which
is charged at $0.09/GB beyond the first 100GB/per customer for the first
10TB/month. Also note that IPv4 data transferred between Availability Zones
within the same region cost $0.01/GB in each direction. IPv6 only incurs this
cost if transferred to a different VPC.

```text
Project: With Public Subnets Only
Module path: examples/complete

 Name  Monthly Qty  Unit  Monthly Cost

 OVERALL TOTAL                   $0.00
──────────────────────────────────
27 cloud resources were detected:
∙ 0 were estimated
∙ 25 were free, rerun with --show-skipped to see details
∙ 2 are not supported yet, rerun with --show-skipped to see details

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━┓
┃ Project                                            ┃ Monthly cost ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━┫
┃ With Public Subnets Only                           ┃ $0.00        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━┛
```

### Example Network with Public & Private Subnets without NAT

If for some reason you would like private subnets without access to the internet
this configuration can achieve that.

```terraform
network = {
  cidr           = "10.10.0.0/16"
  enable_nat     = false
  one_nat        = false
  enable_private = true
  subnets = [
    {
      az      = "us-east-1a"
      public  = "10.10.1.0/24"
      private = "10.10.16.0/20"
    },
    {
      az      = "us-east-1b"
      public  = "10.10.2.0/24"
      private = "10.10.32.0/20"
    },
    {
      az      = "us-east-1c"
      public  = "10.10.3.0/24"
      private = "10.10.48.0/20"
    },
    {
      az      = "us-east-1d"
      public  = "10.10.4.0/24"
      private = "10.10.64.0/20"
    },
    {
      az      = "us-east-1e"
      public  = "10.10.5.0/24"
      private = "10.10.80.0/20"
    },
    {
      az      = "us-east-1f"
      public  = "10.10.6.0/24"
      private = "10.10.96.0/20"
    },
  ]
}
```

[![infracost](https://img.shields.io/endpoint?url=https://dashboard.api.infracost.io/shields/json/6e706676-64ba-43db-97b9-bd92f9272474/repos/4290fbbd-b821-4df7-afde-7addb4d74b8c/branch/0641e65d-bfd2-44c8-9eee-c7511ac75eca/With%2520Public%2520%2526%2520Private%2520Subnets%2520no%252FNAT)](https://dashboard.infracost.io/org/bendoerr/repos/4290fbbd-b821-4df7-afde-7addb4d74b8c?tab=settings)

At a base level this configuration incurs no cost. However, take note of future
IPv4 active addresses beginning to cost mention above.

**Important Data Transfer Costs to Keep in Mind:** While the VPC at rest does
not cost, be sure to estimate Data Transfer OUT from AWS to the Internet which
is charged at $0.09/GB beyond the first 100GB/per customer for the first
10TB/month. Also note that IPv4 data transferred between Availability Zones
within the same region cost $0.01/GB in each direction. IPv6 only incurs this
cost if transferred to a different VPC.

```text
Project: With Public & Private Subnets no/NAT
Module path: examples/complete

 Name  Monthly Qty  Unit  Monthly Cost

 OVERALL TOTAL                   $0.00
──────────────────────────────────
40 cloud resources were detected:
∙ 0 were estimated
∙ 38 were free, rerun with --show-skipped to see details
∙ 2 are not supported yet, rerun with --show-skipped to see details

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━┓
┃ Project                                            ┃ Monthly cost ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━┫
┃ With Public & Private Subnets no/NAT               ┃ $0.00        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━┛
```

### Example Network with Public & Private Subnets and a Single NAT

This is a good starter Public/Private network topology which will use a single
NAT in the first availability zone for all subnets. If you are spreading your
workload across multiple availability zones for fault tolerance note that in
this configuration the NAT Gateway becomes a single point of failure for
outbound traffic.

```terraform
network = {
  cidr           = "10.10.0.0/16"
  enable_nat     = true
  one_nat        = true
  enable_private = true
  subnets = [
    {
      az      = "us-east-1a"
      public  = "10.10.1.0/24"
      private = "10.10.16.0/20"
    },
    {
      az      = "us-east-1b"
      public  = "10.10.2.0/24"
      private = "10.10.32.0/20"
    },
    {
      az      = "us-east-1c"
      public  = "10.10.3.0/24"
      private = "10.10.48.0/20"
    },
    {
      az      = "us-east-1d"
      public  = "10.10.4.0/24"
      private = "10.10.64.0/20"
    },
    {
      az      = "us-east-1e"
      public  = "10.10.5.0/24"
      private = "10.10.80.0/20"
    },
    {
      az      = "us-east-1f"
      public  = "10.10.6.0/24"
      private = "10.10.96.0/20"
    },
  ]
}
```

[![infracost](https://img.shields.io/endpoint?url=https://dashboard.api.infracost.io/shields/json/6e706676-64ba-43db-97b9-bd92f9272474/repos/4290fbbd-b821-4df7-afde-7addb4d74b8c/branch/0641e65d-bfd2-44c8-9eee-c7511ac75eca/With%2520Public%2520%2526%2520Private%2520Subnets%2520with%2520one%2520NAT)](https://dashboard.infracost.io/org/bendoerr/repos/4290fbbd-b821-4df7-afde-7addb4d74b8c?tab=settings)

🚨Using a NAT Gateway costs about $32.85/month to exist. Additionally, NAT
Gateway's charge $0.045/1 GB data processed. There is no charge between the NAT
Gateway and resources in the same availability zone, however data transfers
between the NAT Gateway and resources in different availability zones do incur
standard EC2 data transfer charges.

This cost example assumes 50GB of processed data at the NAT and that 4/5ths of
that data is being distributed to other availability zones.

```text
Project: With Public & Private Subnets with one NAT
Module path: examples/complete

 Name                                                            Monthly Qty  Unit   Monthly Cost

 aws_data_transfer.my_region
 └─ Intra-region data transfer                                            80  GB            $0.80

 module.aws_defaults.module.vpc_default.aws_nat_gateway.this[0]
 ├─ NAT gateway                                                          730  hours        $32.85
 └─ Data processed                                                        50  GB            $2.25

 OVERALL TOTAL                                                                             $35.90
──────────────────────────────────
44 cloud resources were detected:
∙ 2 were estimated, all of which include usage-based costs, see https://infracost.io/usage-file
∙ 40 were free, rerun with --show-skipped to see details
∙ 2 are not supported yet, rerun with --show-skipped to see details

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━┓
┃ Project                                            ┃ Monthly cost ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━┫
┃ With Public & Private Subnets with one NAT         ┃ $36          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━┛
```

### Example Network with Public & Private Subnets and a NAT per AZ

This is the more robust Public/Private topology that allows for failed regions
to not take down NATing.

```terraform
network = {
  cidr           = "10.10.0.0/16"
  enable_nat     = true
  one_nat        = false
  enable_private = true
  subnets = [
    {
      az      = "us-east-1a"
      public  = "10.10.1.0/24"
      private = "10.10.16.0/20"
    },
    {
      az      = "us-east-1b"
      public  = "10.10.2.0/24"
      private = "10.10.32.0/20"
    },
    {
      az      = "us-east-1c"
      public  = "10.10.3.0/24"
      private = "10.10.48.0/20"
    },
    {
      az      = "us-east-1d"
      public  = "10.10.4.0/24"
      private = "10.10.64.0/20"
    },
    {
      az      = "us-east-1e"
      public  = "10.10.5.0/24"
      private = "10.10.80.0/20"
    },
    {
      az      = "us-east-1f"
      public  = "10.10.6.0/24"
      private = "10.10.96.0/20"
    },
  ]
}
```

[![infracost](https://img.shields.io/endpoint?url=https://dashboard.api.infracost.io/shields/json/6e706676-64ba-43db-97b9-bd92f9272474/repos/4290fbbd-b821-4df7-afde-7addb4d74b8c/branch/0641e65d-bfd2-44c8-9eee-c7511ac75eca/With%2520Public%2520%2526%2520Private%2520Subnets%2520with%2520NAT%2520per%2520AZ)](https://dashboard.infracost.io/org/bendoerr/repos/4290fbbd-b821-4df7-afde-7addb4d74b8c?tab=settings)

🚨Using a NAT Gateway costs about $32.85/month to exist. Additionally, NAT
Gateway's charge $0.045/1 GB data processed. There is no charge between the NAT
Gateway and resources in the same availability zone, however data transfers
between the NAT Gateway and resources in different availability zones do incur
standard EC2 data transfer charges.

This cost example assumes 50GB of processed data at the NAT without any need for
inter-region data transfer.

```text
Project: With Public & Private Subnets with NAT per AZ
Module path: examples/complete

 Name                                                            Monthly Qty  Unit   Monthly Cost

 module.aws_defaults.module.vpc_default.aws_nat_gateway.this[0]
 ├─ NAT gateway                                                          730  hours        $32.85
 └─ Data processed                                                        50  GB            $2.25

 module.aws_defaults.module.vpc_default.aws_nat_gateway.this[1]
 ├─ NAT gateway                                                          730  hours        $32.85
 └─ Data processed                                                        50  GB            $2.25

 module.aws_defaults.module.vpc_default.aws_nat_gateway.this[2]
 ├─ NAT gateway                                                          730  hours        $32.85
 └─ Data processed                                                        50  GB            $2.25

 module.aws_defaults.module.vpc_default.aws_nat_gateway.this[3]
 ├─ NAT gateway                                                          730  hours        $32.85
 └─ Data processed                                                        50  GB            $2.25

 module.aws_defaults.module.vpc_default.aws_nat_gateway.this[4]
 ├─ NAT gateway                                                          730  hours        $32.85
 └─ Data processed                                                        50  GB            $2.25

 module.aws_defaults.module.vpc_default.aws_nat_gateway.this[5]
 ├─ NAT gateway                                                          730  hours        $32.85
 └─ Data processed                                                        50  GB            $2.25

 OVERALL TOTAL                                                                            $210.60
──────────────────────────────────
63 cloud resources were detected:
∙ 6 were estimated, all of which include usage-based costs, see https://infracost.io/usage-file
∙ 55 were free, rerun with --show-skipped to see details
∙ 2 are not supported yet, rerun with --show-skipped to see details

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━┓
┃ Project                                            ┃ Monthly cost ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━┫
┃ With Public & Private Subnets with NAT per AZ      ┃ $211         ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━┛
```

## IPv6 Support

This module now supports IPv6 networking through the `ip_mode` variable in the
network configuration. Three modes are available:

### IPv4 Only (Default)

```terraform
network = {
  cidr           = "10.10.0.0/16"
  enable_nat     = false
  one_nat        = false
  enable_private = false
  ip_mode        = "ipv4"  # Default, can be omitted
  subnets = [
    {
      az      = "us-east-1a"
      public  = "10.10.1.0/24"
      private = ""
    },
  ]
}
```

This is the default behavior with no changes to existing configurations. IPv6
is disabled and only IPv4 addresses are used.

### Dual-Stack (IPv4 + IPv6)

```terraform
network = {
  cidr           = "10.10.0.0/16"
  enable_nat     = false
  one_nat        = false
  enable_private = true
  ip_mode        = "dual-stack"
  subnets = [
    {
      az      = "us-east-1a"
      public  = "10.10.1.0/24"
      private = "10.10.11.0/24"
    },
    {
      az      = "us-east-1b"
      public  = "10.10.2.0/24"
      private = "10.10.12.0/24"
    },
  ]
}
```

In dual-stack mode:

- AWS automatically assigns a `/56` IPv6 CIDR block to the VPC
- Subnets receive both IPv4 and IPv6 addresses
- Public subnets get `/64` IPv6 CIDR blocks (prefixes 0, 1, 2, ...)
- Private subnets get `/64` IPv6 CIDR blocks (prefixes starting after public subnets)
- Instances automatically receive IPv6 addresses on creation
- Egress-only Internet Gateway is created for private subnet IPv6 traffic
- NAT gateway behavior remains unchanged for IPv4 traffic

### IPv6-Only

```terraform
network = {
  cidr           = "10.20.0.0/16"
  enable_nat     = false  # Ignored in IPv6-only mode
  one_nat        = false  # Ignored in IPv6-only mode
  enable_private = true
  ip_mode        = "ipv6-only"
  subnets = [
    {
      az      = "us-east-1a"
      public  = "10.20.1.0/24"
      private = "10.20.11.0/24"
    },
    {
      az      = "us-east-1b"
      public  = "10.20.2.0/24"
      private = "10.20.12.0/24"
    },
  ]
}
```

In IPv6-only mode:

- Subnets are configured with `ipv6_native = true` — EC2 instances receive IPv6
  addresses via DHCPv6 and do not require private IPv4 addresses. The VPC itself
  still has an IPv4 CIDR block (AWS does not allow removing it), but subnets in
  this mode do not assign IPv4 addresses to instances on creation.
- NAT gateways are automatically disabled (not needed for IPv6)
- Egress-only Internet Gateway handles outbound IPv6 traffic
- No IPv4 public address costs
- **Note:** IPv4 CIDR values in the `subnets` configuration are required by the
  variable schema but are ignored — the VPC module sets `cidr_block = null` for
  IPv6-native subnets.

### Migration Guide

> ⚠️ **There is NO in-place migration path from IPv4-only subnets to IPv6-only
> subnets.** AWS does not support converting an existing IPv4-only subnet to an
> IPv6-native subnet in place. If you are on `ip_mode = "ipv4"` and want
> `ip_mode = "ipv6-only"`, you must first migrate to dual-stack (`ip_mode =
> "dual-stack"`), then to IPv6-only — and the transition to IPv6-only **will
> recreate your subnets** and any resources inside them. Plan for a maintenance
> window and workload migration before attempting this.

**Migrating from IPv4-only to dual-stack:**

1. Add `ip_mode = "dual-stack"` to your network configuration
2. Run `terraform plan` to review changes
3. Apply changes - this is a non-breaking change:
   - Existing IPv4 functionality remains unchanged
   - IPv6 CIDR blocks are added to VPC and subnets
   - New resources will receive both IPv4 and IPv6 addresses

**Migrating from dual-stack to IPv6-only:**

⚠️ **This is a breaking change** that will recreate subnets:

1. Update `ip_mode = "ipv6-only"`
2. Set `enable_nat = false` (NAT gateways not used with IPv6-only)
3. Understand that:
   - Existing resources in subnets will need to be recreated
   - IPv4 addresses will be removed from subnets
   - Only IPv6 connectivity will be available
4. Plan for workload migration or maintenance window

**Rolling back:**

To revert from dual-stack or IPv6-only back to IPv4-only:

- Change `ip_mode = "ipv4"`
- For IPv6-only → IPv4, expect subnet recreation
- For dual-stack → IPv4, IPv6 addresses are removed but subnets remain

### IPv6 Outputs

When IPv6 is enabled (dual-stack or IPv6-only), additional outputs are available:

- `vpc_ipv6_cidr_block` - The IPv6 CIDR block assigned to the VPC
- `vpc_public_subnet_ipv6_cidr_blocks` - List of IPv6 CIDR blocks for public subnets
- `vpc_private_subnet_ipv6_cidr_blocks` - List of IPv6 CIDR blocks for private subnets
- `vpc_egress_only_internet_gateway_id` - ID of the egress-only Internet Gateway

<!-- BEGIN_TF_DOCS -->

### Requirements

| Name                                                                     | Version |
| ------------------------------------------------------------------------ | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | ~> 5.0  |

### Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 5.31.0  |

### Modules

| Name                                                                                         | Source                                             | Version |
| -------------------------------------------------------------------------------------------- | -------------------------------------------------- | ------- |
| <a name="module_iam_account"></a> [iam_account](#module_iam_account)                         | terraform-aws-modules/iam/aws//modules/iam-account | 5.33.0  |
| <a name="module_label_account_alias"></a> [label_account_alias](#module_label_account_alias) | bendoerr-terraform-modules/label/null              | 0.4.1   |
| <a name="module_label_monthly_total"></a> [label_monthly_total](#module_label_monthly_total) | bendoerr-terraform-modules/label/null              | 0.4.1   |
| <a name="module_label_network"></a> [label_network](#module_label_network)                   | bendoerr-terraform-modules/label/null              | 0.4.1   |
| <a name="module_vpc_default"></a> [vpc_default](#module_vpc_default)                         | terraform-aws-modules/vpc/aws                      | 5.4.0   |

### Resources

| Name                                                                                                                                                          | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_budgets_budget.monthly_total](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget)                                | resource    |
| [aws_ebs_default_kms_key.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_default_kms_key)                            | resource    |
| [aws_ebs_encryption_by_default.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_encryption_by_default)                | resource    |
| [aws_ec2_serial_console_access.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_serial_console_access)                | resource    |
| [aws_ecs_account_setting_default.awsvpc_trunking](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_account_setting_default)    | resource    |
| [aws_ecs_account_setting_default.container_insights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_account_setting_default) | resource    |
| [aws_kms_alias.ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias)                                                 | data source |

### Inputs

| Name                                                                                          | Description                                      | Type                                                                                                                                                                                                                                                                                                                      | Default                                                                                                                                                                                                                       | Required |
| --------------------------------------------------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------: |
| <a name="input_budget_alert_emails"></a> [budget_alert_emails](#input_budget_alert_emails)    | n/a                                              | `set(string)`                                                                                                                                                                                                                                                                                                             | n/a                                                                                                                                                                                                                           |   yes    |
| <a name="input_budget_monthly_limit"></a> [budget_monthly_limit](#input_budget_monthly_limit) | n/a                                              | `string`                                                                                                                                                                                                                                                                                                                  | n/a                                                                                                                                                                                                                           |   yes    |
| <a name="input_context"></a> [context](#input_context)                                        | Shared Context from Ben's terraform-null-context | <pre>object({<br> attributes = list(string)<br> dns_namespace = string<br> environment = string<br> instance = string<br> instance_short = string<br> namespace = string<br> region = string<br> region_short = string<br> role = string<br> role_short = string<br> project = string<br> tags = map(string)<br> })</pre> | n/a                                                                                                                                                                                                                           |   yes    |
| <a name="input_iam_alias_postfix"></a> [iam_alias_postfix](#input_iam_alias_postfix)          | n/a                                              | `string`                                                                                                                                                                                                                                                                                                                  | n/a                                                                                                                                                                                                                           |   yes    |
| <a name="input_network"></a> [network](#input_network)                                        | n/a                                              | <pre>object({<br> cidr = string<br> enable_nat = bool<br> one_nat = bool<br> enable_private = bool<br> subnets = list(object({<br> az = string<br> public = string<br> private = string<br> }))<br> })</pre>                                                                                                              | <pre>{<br> "cidr": "0.0.0.0/0",<br> "enable_nat": false,<br> "enable_private": false,<br> "one_nat": true,<br> "subnets": [<br> {<br> "az": "us-east-1a",<br> "private": "",<br> "public": "0.0.0.0/0"<br> }<br> ]<br>}</pre> |    no    |

### Outputs

| Name                                                                                                                                                        | Description |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| <a name="output_aws_budgets_budget_monthly_total_account"></a> [aws_budgets_budget_monthly_total_account](#output_aws_budgets_budget_monthly_total_account) | n/a         |
| <a name="output_aws_budgets_budget_monthly_total_name"></a> [aws_budgets_budget_monthly_total_name](#output_aws_budgets_budget_monthly_total_name)          | n/a         |
| <a name="output_vpc_azs"></a> [vpc_azs](#output_vpc_azs)                                                                                                    | n/a         |
| <a name="output_vpc_id"></a> [vpc_id](#output_vpc_id)                                                                                                       | n/a         |
| <a name="output_vpc_private_subnet_ids"></a> [vpc_private_subnet_ids](#output_vpc_private_subnet_ids)                                                       | n/a         |
| <a name="output_vpc_public_subnet_ids"></a> [vpc_public_subnet_ids](#output_vpc_public_subnet_ids)                                                          | n/a         |

<!-- END_TF_DOCS -->

## Roadmap

[<img alt="GitHub issues" src="https://img.shields.io/github/issues/bendoerr-terraform-modules/terraform-aws-defaults?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/issues)

See the
[open issues](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/issues)
for a list of proposed features (and known issues).

## Contributing

[<img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/bendoerr-terraform-modules/terraform-aws-defaults?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/pulls)

Contributions are what make the open source community such an amazing place to
be learn, inspire, and create. Any contributions you make are **greatly
appreciated**.

- If you have suggestions for adding or removing projects, feel free to
  [open an issue](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/issues/new)
  to discuss it, or directly create a pull request after you edit the
  _README.md_ file with necessary changes.
- Please make sure you check your spelling and grammar.
- Create individual PR for each suggestion.

### Creating A Pull Request

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

[<img alt="GitHub License" src="https://img.shields.io/github/license/bendoerr-terraform-modules/terraform-aws-defaults?logo=opensourceinitiative">](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/blob/main/LICENSE.txt)

Distributed under the MIT License. See
[LICENSE](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/blob/main/LICENSE.txt)
for more information.

## Authors

[<img alt="GitHub contributors" src="https://img.shields.io/github/contributors/bendoerr-terraform-modules/terraform-aws-defaults?logo=github">](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/graphs/contributors)

- **Benjamin R. Doerr** - _Terraformer_ -
  [Benjamin R. Doerr](https://github.com/bendoerr/) - _Built Ben's Terraform
  Modules_

## Supported Versions

Only the latest tagged version is supported.

## Reporting a Vulnerability

See [SECURITY.md](SECURITY.md).

## Acknowledgements

- [ShaanCoding (ReadME Generator)](https://github.com/ShaanCoding/ReadME-Generator)
- [OpenSSF - Helping me follow best practices](https://openssf.org/)
- [StepSecurity - Helping me follow best practices](https://app.stepsecurity.io/)
- [Infracost - Better than AWS Calculator](https://www.infracost.io/)
