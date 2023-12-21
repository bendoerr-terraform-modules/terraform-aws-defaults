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
