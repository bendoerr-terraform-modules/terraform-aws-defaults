variable "namespace" {
  type        = string
  description = <<-EOT
    Element to ensure resources are generated with names that are globally
    unique and do not collide. This should be a short key such as initials.
    EOT
}

variable "environment" {
  type        = string
  default     = ""
  description = <<-EOT
    Element to identify the region and/or the role. If not provided this element
    defaults to <role_short>-<region_short>(-<instance_short>).
    EOT
}

variable "role" {
  type        = string
  default     = ""
  description = <<-EOT
    A simple name for the hosting provider account or workspace. Included in
    tags to ensure that identification is simple across accounts. Examples
    'production', 'development', 'main'.
    EOT
}

variable "role_short" {
  type        = string
  default     = ""
  description = <<-EOT
    Shortened version of the 'role'.
    Automatic shortening is done by removal of vowels unless handled by special
    cases such as 'production' => 'prod', or 'development' => 'dev'.
    EOT
}

variable "region" {
  type        = string
  default     = ""
  description = <<-EOT
    Key for the hosting provider region.
    EOT
}

variable "region_short" {
  type        = string
  default     = ""
  description = <<-EOT
    Shortened version of the 'region'.
    Automatic shortening is done by removal of vowels unless handled by special
    cases such as 'us-east-1' => 'ue1', or 'us-west-2' => 'uw2'.
    EOT
}

variable "instance" {
  type        = string
  default     = ""
  description = <<-EOT
    Element to identify a tenant or copy of an environment (blue-green
    deployments). This is not used often.
    EOT
}

variable "instance_short" {
  type        = string
  default     = ""
  description = <<-EOT
    Shortened version of the 'instance'.
    Automatic shortening is done by removal of vowels.
    EOT
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional id elements that would be appended."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to include."
}

variable "context" {
  type = any
  default = {
    attributes             = []
    aws_account_name       = ""
    aws_account_name_short = ""
    aws_region             = ""
    aws_region_short       = ""
    dns_namespace          = ""
    environment            = ""
    instance               = ""
    instance_short         = ""
    project                = ""
    namespace              = ""
    tags                   = {}
  }
  description = "Allows the merging of an existing context with this one."
}

variable "project" {
  type        = string
  default     = ""
  description = "Name of the project or application, this can override the context's project"
}

variable "budget_monthly_limit" {
  type        = string
  description = ""
}

variable "budget_alert_emails" {
  type        = set(string)
  description = ""
}

variable "iam_alias_postfix" {
  type        = string
  description = ""
}

variable "network" {
  type = object({
    cidr           = string
    enable_nat     = bool
    one_nat        = bool
    enable_private = bool
    ip_mode        = optional(string, "ipv4")
    subnets = list(object({
      az      = string
      public  = string
      private = string
    }))
  })
  default = {
    cidr           = "10.20.0.0/16"
    enable_nat     = false
    one_nat        = false
    enable_private = true
    ip_mode        = "ipv6-only"
    subnets = [
      # Note: the `public` and `private` values below are IPv4 CIDRs required
      # by the variable schema but are NOT used in IPv6-only mode. The
      # underlying VPC module sets cidr_block = null for IPv6-native subnets,
      # so these IPv4 ranges are never assigned to actual subnet resources.
      {
        az      = "us-east-1a"
        public  = "10.20.1.0/24"
        private = "10.20.11.0/24"
      },
      {
        az      = "us-east-1b"
        public  = "10.20.2.0/24"
        private = "10.20.12.0/24"
      }
    ]
  }
  description = "Network configuration including CIDR, subnets, NAT, and IPv6 ip_mode."
}
