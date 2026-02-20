variable "context" {
  type = object({
    attributes     = list(string)
    dns_namespace  = string
    environment    = string
    instance       = string
    instance_short = string
    namespace      = string
    region         = string
    region_short   = string
    role           = string
    role_short     = string
    project        = string
    tags           = map(string)
  })
  description = "Shared Context from Ben's terraform-null-context"
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
    cidr           = "0.0.0.0/0"
    enable_nat     = false
    one_nat        = true
    enable_private = false
    ip_mode        = "ipv4"
    subnets = [
      {
        az      = "us-east-1a"
        public  = "0.0.0.0/0"
        private = ""
      }
    ]
  }
  description = "Network configuration for VPC. ip_mode can be 'ipv4' (default), 'dual-stack', or 'ipv6-only'."

  validation {
    condition     = contains(["ipv4", "dual-stack", "ipv6-only"], var.network.ip_mode)
    error_message = "ip_mode must be one of: ipv4, dual-stack, ipv6-only"
  }
}
