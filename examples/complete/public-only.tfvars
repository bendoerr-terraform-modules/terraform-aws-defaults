# Demonstrates the optional() defaults: enable_nat=false, one_nat=true,
# enable_private=false are all module defaults, so we omit them here.
network = {
  cidr = "10.10.0.0/16"
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
