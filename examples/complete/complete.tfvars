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
  cidr           = "10.10.0.0/16"
  enable_nat     = false
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
  ]
}
