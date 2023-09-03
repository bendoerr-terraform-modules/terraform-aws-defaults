module "context" {
  source         = "git@github.com:bendoerr-terraform-modules/terraform-null-context?ref=v0.4.0"
  namespace      = var.namespace
  environment    = var.environment
  role           = var.role
  role_short     = var.role_short
  region         = var.region
  region_short   = var.region_short
  instance       = var.instance
  instance_short = var.instance_short
  project        = var.project
  attributes     = var.attributes
  tags           = var.tags
}