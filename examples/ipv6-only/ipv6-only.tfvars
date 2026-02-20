namespace      = "ex"
environment    = "env"
role           = "production"
role_short     = "prd"
region         = "us-west-2"
region_short   = "uw2"
instance       = "demo"
instance_short = "dmo"
project        = "test"
attributes = [
  "attr1"
]
tags = {
  ExtraTag = "ExtraTagValue"
}

iam_alias_postfix = "testing-sandbox"

budget_monthly_limit = 1
budget_alert_emails  = ["craftsman@bendoerr.me"]

network = {
  cidr           = "10.20.0.0/16"
  enable_nat     = false
  one_nat        = false
  enable_private = true
  ip_mode        = "ipv6-only"
  # Note: public/private CIDRs are required by the variable schema but are NOT
  # used in IPv6-only mode. The underlying VPC module sets cidr_block = null
  # for IPv6-native subnets, so these IPv4 ranges are never assigned.
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
